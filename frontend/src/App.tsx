import { useCallback, useEffect, useState } from 'react'
import './App.css'
import { createTodo, deleteTodo, getTodos, getTodoStats, updateTodo } from './api/todos'
import { StatsCard } from './components/StatsCard'
import { TodoForm } from './components/TodoForm'
import { TodoList } from './components/TodoList'
import type { Todo, TodoCreate, TodoStats, TodoStatus } from './types/todo'

function App() {
  const [todos, setTodos] = useState<Todo[]>([])
  const [stats, setStats] = useState<TodoStats | null>(null)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState<string | null>(null)

  const fetchData = useCallback(async () => {
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
  }, [])

  useEffect(() => {
    fetchData()
  }, [fetchData])

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
