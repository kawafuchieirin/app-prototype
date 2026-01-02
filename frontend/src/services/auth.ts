/**
 * Cognito認証サービス
 * AWS CognitoとcognitoーLocalの両方に対応したカスタム認証クライアント
 */

interface CognitoConfig {
  endpoint: string
  userPoolId: string
  clientId: string
}

interface AuthTokens {
  accessToken: string
  idToken: string
  refreshToken: string
}

interface CognitoUser {
  username: string
  email?: string
  sub: string
}

const STORAGE_KEY = 'cognito_tokens'

function getConfig(): CognitoConfig {
  const region = import.meta.env.VITE_AWS_REGION || 'ap-northeast-1'
  const userPoolId = import.meta.env.VITE_COGNITO_USER_POOL_ID || ''
  const clientId = import.meta.env.VITE_COGNITO_CLIENT_ID || ''
  const customEndpoint = import.meta.env.VITE_COGNITO_ENDPOINT

  // カスタムエンドポイントが設定されている場合（ローカル環境）
  if (customEndpoint) {
    return {
      endpoint: customEndpoint,
      userPoolId,
      clientId,
    }
  }

  // AWS環境
  return {
    endpoint: `https://cognito-idp.${region}.amazonaws.com`,
    userPoolId,
    clientId,
  }
}

async function cognitoRequest<T>(target: string, payload: object): Promise<T> {
  const config = getConfig()

  const response = await fetch(config.endpoint, {
    method: 'POST',
    headers: {
      'Content-Type': 'application/x-amz-json-1.1',
      'X-Amz-Target': `AWSCognitoIdentityProviderService.${target}`,
    },
    body: JSON.stringify(payload),
  })

  const data = await response.json()

  if (!response.ok) {
    const errorMessage = data.message || data.__type || 'Authentication failed'
    throw new Error(errorMessage)
  }

  return data
}

function saveTokens(tokens: AuthTokens): void {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(tokens))
}

function getStoredTokens(): AuthTokens | null {
  const stored = localStorage.getItem(STORAGE_KEY)
  if (!stored) return null

  try {
    return JSON.parse(stored)
  } catch {
    return null
  }
}

function clearTokens(): void {
  localStorage.removeItem(STORAGE_KEY)
}

function decodeJwtPayload(token: string): Record<string, unknown> {
  const base64Url = token.split('.')[1]
  const base64 = base64Url.replace(/-/g, '+').replace(/_/g, '/')
  const jsonPayload = decodeURIComponent(
    atob(base64)
      .split('')
      .map((c) => '%' + ('00' + c.charCodeAt(0).toString(16)).slice(-2))
      .join('')
  )
  return JSON.parse(jsonPayload)
}

function isTokenExpired(token: string): boolean {
  try {
    const payload = decodeJwtPayload(token)
    const exp = payload.exp as number
    return Date.now() >= exp * 1000
  } catch {
    return true
  }
}

export async function signIn(email: string, password: string): Promise<CognitoUser> {
  const config = getConfig()

  const result = await cognitoRequest<{
    AuthenticationResult?: {
      AccessToken: string
      IdToken: string
      RefreshToken: string
    }
    ChallengeName?: string
  }>('InitiateAuth', {
    AuthFlow: 'USER_PASSWORD_AUTH',
    ClientId: config.clientId,
    AuthParameters: {
      USERNAME: email,
      PASSWORD: password,
    },
  })

  if (result.ChallengeName) {
    throw new Error(`認証チャレンジが必要です: ${result.ChallengeName}`)
  }

  if (!result.AuthenticationResult) {
    throw new Error('認証結果が取得できませんでした')
  }

  const tokens: AuthTokens = {
    accessToken: result.AuthenticationResult.AccessToken,
    idToken: result.AuthenticationResult.IdToken,
    refreshToken: result.AuthenticationResult.RefreshToken,
  }

  saveTokens(tokens)

  return getUserFromToken(tokens.idToken)
}

export async function signUp(
  email: string,
  password: string
): Promise<{ needsConfirmation: boolean }> {
  const config = getConfig()

  const result = await cognitoRequest<{
    UserConfirmed: boolean
  }>('SignUp', {
    ClientId: config.clientId,
    Username: email,
    Password: password,
    UserAttributes: [
      {
        Name: 'email',
        Value: email,
      },
    ],
  })

  return {
    needsConfirmation: !result.UserConfirmed,
  }
}

export async function confirmSignUp(email: string, code: string): Promise<void> {
  const config = getConfig()

  await cognitoRequest('ConfirmSignUp', {
    ClientId: config.clientId,
    Username: email,
    ConfirmationCode: code,
  })
}

export async function signOut(): Promise<void> {
  const tokens = getStoredTokens()

  if (tokens) {
    try {
      await cognitoRequest('GlobalSignOut', {
        AccessToken: tokens.accessToken,
      })
    } catch {
      // サインアウトエラーは無視（トークンが既に無効な場合など）
    }
  }

  clearTokens()
}

export async function refreshTokens(): Promise<AuthTokens | null> {
  const tokens = getStoredTokens()
  if (!tokens?.refreshToken) return null

  const config = getConfig()

  try {
    const result = await cognitoRequest<{
      AuthenticationResult: {
        AccessToken: string
        IdToken: string
      }
    }>('InitiateAuth', {
      AuthFlow: 'REFRESH_TOKEN_AUTH',
      ClientId: config.clientId,
      AuthParameters: {
        REFRESH_TOKEN: tokens.refreshToken,
      },
    })

    const newTokens: AuthTokens = {
      accessToken: result.AuthenticationResult.AccessToken,
      idToken: result.AuthenticationResult.IdToken,
      refreshToken: tokens.refreshToken,
    }

    saveTokens(newTokens)
    return newTokens
  } catch {
    clearTokens()
    return null
  }
}

export async function getAccessToken(): Promise<string | null> {
  const tokens = getStoredTokens()
  if (!tokens) return null

  // アクセストークンが期限切れの場合、リフレッシュを試行
  if (isTokenExpired(tokens.accessToken)) {
    const refreshed = await refreshTokens()
    return refreshed?.accessToken ?? null
  }

  return tokens.accessToken
}

export function getCurrentUser(): CognitoUser | null {
  const tokens = getStoredTokens()
  if (!tokens?.idToken) return null

  // トークンが期限切れの場合はnullを返す
  if (isTokenExpired(tokens.idToken)) {
    return null
  }

  try {
    return getUserFromToken(tokens.idToken)
  } catch {
    return null
  }
}

function getUserFromToken(idToken: string): CognitoUser {
  const payload = decodeJwtPayload(idToken)

  return {
    username: (payload['cognito:username'] as string) || (payload.sub as string),
    email: payload.email as string | undefined,
    sub: payload.sub as string,
  }
}
