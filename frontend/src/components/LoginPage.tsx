import { useState } from 'react'
import { useAuth } from '../contexts/AuthContext'
import './LoginPage.css'

type AuthMode = 'signIn' | 'signUp' | 'confirm'

export function LoginPage() {
  const { signIn, signUp, confirmSignUp } = useAuth()
  const [mode, setMode] = useState<AuthMode>('signIn')
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [confirmCode, setConfirmCode] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [isLoading, setIsLoading] = useState(false)

  const handleSignIn = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      await signIn(email, password)
    } catch (err) {
      setError(err instanceof Error ? err.message : 'ログインに失敗しました')
    } finally {
      setIsLoading(false)
    }
  }

  const handleSignUp = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      const result = await signUp(email, password)
      if (result.needsConfirmation) {
        setMode('confirm')
      }
    } catch (err) {
      setError(err instanceof Error ? err.message : 'アカウント作成に失敗しました')
    } finally {
      setIsLoading(false)
    }
  }

  const handleConfirm = async (e: React.FormEvent) => {
    e.preventDefault()
    setError(null)
    setIsLoading(true)

    try {
      await confirmSignUp(email, confirmCode)
      setMode('signIn')
      setError(null)
      alert('アカウントが確認されました。ログインしてください。')
    } catch (err) {
      setError(err instanceof Error ? err.message : '確認コードが無効です')
    } finally {
      setIsLoading(false)
    }
  }

  if (mode === 'confirm') {
    return (
      <div className="login-container">
        <div className="login-card">
          <h1>確認コードを入力</h1>
          <p className="login-subtitle">メールに送信された確認コードを入力してください</p>

          {error && <div className="login-error">{error}</div>}

          <form onSubmit={handleConfirm}>
            <div className="form-group">
              <label htmlFor="confirmCode">確認コード</label>
              <input
                id="confirmCode"
                type="text"
                value={confirmCode}
                onChange={(e) => setConfirmCode(e.target.value)}
                placeholder="123456"
                required
                disabled={isLoading}
              />
            </div>

            <button type="submit" className="login-button" disabled={isLoading}>
              {isLoading ? '確認中...' : '確認'}
            </button>
          </form>

          <div className="login-footer">
            <button className="link-button" onClick={() => setMode('signIn')}>
              ログインに戻る
            </button>
          </div>
        </div>
      </div>
    )
  }

  return (
    <div className="login-container">
      <div className="login-card">
        <h1>{mode === 'signIn' ? 'ログイン' : 'アカウント作成'}</h1>
        <p className="login-subtitle">ToDo Dashboardへようこそ</p>

        {error && <div className="login-error">{error}</div>}

        <form onSubmit={mode === 'signIn' ? handleSignIn : handleSignUp}>
          <div className="form-group">
            <label htmlFor="email">メールアドレス</label>
            <input
              id="email"
              type="email"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
              placeholder="example@email.com"
              required
              disabled={isLoading}
            />
          </div>

          <div className="form-group">
            <label htmlFor="password">パスワード</label>
            <input
              id="password"
              type="password"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
              placeholder="********"
              required
              disabled={isLoading}
              minLength={8}
            />
            {mode === 'signUp' && (
              <p className="password-hint">
                8文字以上、大文字・小文字・数字・記号を含む
              </p>
            )}
          </div>

          <button type="submit" className="login-button" disabled={isLoading}>
            {isLoading
              ? mode === 'signIn'
                ? 'ログイン中...'
                : '作成中...'
              : mode === 'signIn'
                ? 'ログイン'
                : 'アカウント作成'}
          </button>
        </form>

        <div className="login-footer">
          {mode === 'signIn' ? (
            <p>
              アカウントをお持ちでない方は
              <button className="link-button" onClick={() => setMode('signUp')}>
                こちら
              </button>
            </p>
          ) : (
            <p>
              既にアカウントをお持ちの方は
              <button className="link-button" onClick={() => setMode('signIn')}>
                こちら
              </button>
            </p>
          )}
        </div>
      </div>
    </div>
  )
}
