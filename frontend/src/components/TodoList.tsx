import type { Todo, TodoStatus } from '../types/todo'
import { TodoItem } from './TodoItem'

interface TodoListProps {
  todos: Todo[]
  onStatusChange: (id: string, status: TodoStatus) => void
  onDelete: (id: string) => void
}

export function TodoList({ todos, onStatusChange, onDelete }: TodoListProps) {
  if (todos.length === 0) {
    return <div className="empty-state">No tasks yet. Add one above!</div>
  }

  const sortedTodos = [...todos].sort((a, b) => {
    const statusOrder = { in_progress: 0, pending: 1, completed: 2 }
    return statusOrder[a.status] - statusOrder[b.status]
  })

  return (
    <div className="todo-list">
      {sortedTodos.map((todo) => (
        <TodoItem
          key={todo.id}
          todo={todo}
          onStatusChange={onStatusChange}
          onDelete={onDelete}
        />
      ))}
    </div>
  )
}
