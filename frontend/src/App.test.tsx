import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import App from './App'
import { AuthProvider } from './contexts/AuthContext'

// 認証サービスをモック
vi.mock('./services/auth', () => ({
  getCurrentUser: vi.fn(() => ({
    username: 'test-user',
    email: 'test@example.com',
    sub: 'test-sub',
  })),
  getAccessToken: vi.fn(() => Promise.resolve('mock-token')),
  signIn: vi.fn(),
  signUp: vi.fn(),
  confirmSignUp: vi.fn(),
  signOut: vi.fn(),
}))

const mockTodos = [
  {
    id: '1',
    title: 'Test Todo 1',
    description: 'Description 1',
    status: 'pending',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
  },
  {
    id: '2',
    title: 'Test Todo 2',
    description: null,
    status: 'completed',
    created_at: '2024-01-01T00:00:00Z',
    updated_at: '2024-01-01T00:00:00Z',
  },
]

const mockStats = {
  total: 2,
  pending: 1,
  in_progress: 0,
  completed: 1,
  completion_rate: 50.0,
}

describe('App', () => {
  beforeEach(() => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string) => {
        if (url.includes('/todos/stats')) {
          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve(mockStats),
          })
        }
        if (url.includes('/todos')) {
          return Promise.resolve({
            ok: true,
            json: () => Promise.resolve(mockTodos),
          })
        }
        return Promise.reject(new Error('Not found'))
      })
    )
  })

  const renderApp = () =>
    render(
      <AuthProvider>
        <App />
      </AuthProvider>
    )

  it('renders the dashboard title', async () => {
    renderApp()
    await waitFor(() => {
      expect(screen.getByText('ToDo Dashboard')).toBeInTheDocument()
    })
  })

  it('displays user email after authentication', async () => {
    renderApp()
    await waitFor(() => {
      expect(screen.getByText('test@example.com')).toBeInTheDocument()
    })
  })

  it('displays stats after loading', async () => {
    renderApp()
    await waitFor(() => {
      expect(screen.getByText('50%')).toBeInTheDocument()
    })
  })

  it('displays todos after loading', async () => {
    renderApp()
    await waitFor(() => {
      expect(screen.getByText('Test Todo 1')).toBeInTheDocument()
      expect(screen.getByText('Test Todo 2')).toBeInTheDocument()
    })
  })

  it('shows error message on fetch failure', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() => Promise.reject(new Error('Network error')))
    )

    renderApp()
    await waitFor(() => {
      expect(screen.getByText(/Failed to load data/)).toBeInTheDocument()
    })
  })
})
