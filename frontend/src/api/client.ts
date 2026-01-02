import { getAccessToken } from '../services/auth'

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:8001'

async function getAuthHeader(): Promise<Record<string, string>> {
  try {
    const token = await getAccessToken()
    if (token) {
      return { Authorization: `Bearer ${token}` }
    }
  } catch {
    // 認証されていない場合は空のヘッダーを返す
  }
  return {}
}

export async function fetchApi<T>(path: string, options?: RequestInit): Promise<T> {
  const authHeader = await getAuthHeader()

  const response = await fetch(`${API_URL}${path}`, {
    ...options,
    headers: {
      'Content-Type': 'application/json',
      ...authHeader,
      ...options?.headers,
    },
  })

  if (!response.ok) {
    if (response.status === 401) {
      throw new Error('認証が必要です。ログインしてください。')
    }
    throw new Error(`API Error: ${response.status}`)
  }

  if (response.status === 204) {
    return undefined as T
  }

  return response.json()
}
