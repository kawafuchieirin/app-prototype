import { useCallback, useEffect, useState } from 'react'
import * as authService from '../services/auth'
import { AuthContext } from './AuthContextDef'

interface User {
  username: string
  email?: string
}

export function AuthProvider({ children }: { children: React.ReactNode }) {
  const [user, setUser] = useState<User | null>(null)
  const [isLoading, setIsLoading] = useState(true)

  const checkAuth = useCallback(async () => {
    try {
      const currentUser = authService.getCurrentUser()
      if (currentUser) {
        setUser({
          username: currentUser.username,
          email: currentUser.email,
        })
      } else {
        setUser(null)
      }
    } catch {
      setUser(null)
    } finally {
      setIsLoading(false)
    }
  }, [])

  useEffect(() => {
    checkAuth()
  }, [checkAuth])

  const handleSignIn = async (email: string, password: string) => {
    const cognitoUser = await authService.signIn(email, password)
    setUser({
      username: cognitoUser.username,
      email: cognitoUser.email,
    })
  }

  const handleSignUp = async (email: string, password: string) => {
    return await authService.signUp(email, password)
  }

  const handleConfirmSignUp = async (email: string, code: string) => {
    await authService.confirmSignUp(email, code)
  }

  const handleSignOut = async () => {
    await authService.signOut()
    setUser(null)
  }

  const getAccessToken = async (): Promise<string | null> => {
    return await authService.getAccessToken()
  }

  return (
    <AuthContext.Provider
      value={{
        user,
        isLoading,
        isAuthenticated: !!user,
        signIn: handleSignIn,
        signUp: handleSignUp,
        confirmSignUp: handleConfirmSignUp,
        signOut: handleSignOut,
        getAccessToken,
      }}
    >
      {children}
    </AuthContext.Provider>
  )
}
