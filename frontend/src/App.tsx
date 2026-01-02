import { useCallback, useEffect, useState } from 'react'
import './App.css'
import { createTodo, deleteTodo, getTodos, getTodoStats, updateTodo } from './api/todos'
import { LoginPage } from './components/LoginPage'
import { StatsCard } from './components/StatsCard'
import { TodoForm } from './components/TodoForm'
import { TodoList } from './components/TodoList'
import { useAuth } from './contexts/AuthContext'
import type { Todo, TodoCreate, TodoStats, TodoStatus } from './types/todo'

function App() {
  const { isAuthenticated, isLoading: authLoading, user, signOut } = useAuth()
  const [todos, setTodos] = useState<Todo[]>([])
  const [stats, setStats] = useState<TodoStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchData = useCallback(async () => {
    if (!isAuthenticated) return

    try {
      setError(null)
      const [todosData, statsData] = await Promise.all([getTodos(), getTodoStats()])
      setTodos(todosData)
      setStats(statsData)
    } catch (err) {
      setError('Failed to load data. Make sure the backend is running.')
      console.error(err)
    } finally {
      setLoading(false)
    }
  }, [isAuthenticated])

  useEffect(() => {
    if (isAuthenticated) {
      fetchData()
    } else {
      setLoading(false)
    }
  }, [fetchData, isAuthenticated])

  const handleCreate = async (todoCreate: TodoCreate) => {
    try {
      await createTodo(todoCreate)
      await fetchData()
    } catch (err) {
      setError('Failed to create todo')
      console.error(err)
    }
  }

  const handleStatusChange = async (id: string, status: TodoStatus) => {
    try {
      await updateTodo(id, { status })
      await fetchData()
    } catch (err) {
      setError('Failed to update todo')
      console.error(err)
    }
  }

  const handleDelete = async (id: string) => {
    try {
      await deleteTodo(id)
      await fetchData()
    } catch (err) {
      setError('Failed to delete todo')
      console.error(err)
    }
  }

  const handleSignOut = async () => {
    try {
      await signOut()
      setTodos([])
      setStats(null)
    } catch (err) {
      console.error('Sign out error:', err)
    }
  }

  // 認証チェック中
  if (authLoading) {
    return (
      <div className="app">
        <div className="loading">Loading...</div>
      </div>
    )
  }

  // 未認証の場合はログインページを表示
  if (!isAuthenticated) {
    return <LoginPage />
  }

  // データ読み込み中
  if (loading) {
    return (
      <div className="app">
        <div className="loading">Loading...</div>
      </div>
    )
  }

  return (
    <div className="app">
      <header className="app-header">
        <h1>ToDo Dashboard</h1>
        <div className="user-info">
          <span>{user?.email || user?.username}</span>
          <button className="logout-button" onClick={handleSignOut}>
            ログアウト
          </button>
        </div>
      </header>

      {error && <div className="error-message">{error}</div>}

      <main className="app-main">
        {stats && <StatsCard stats={stats} />}

        <section className="todos-section">
          <TodoForm onSubmit={handleCreate} />
          <TodoList todos={todos} onStatusChange={handleStatusChange} onDelete={handleDelete} />
        </section>
      </main>
    </div>
  )
}

export default App
