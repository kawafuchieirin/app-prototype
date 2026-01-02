import type { Todo, TodoStatus } from '../types/todo'

interface TodoItemProps {
  todo: Todo
  onStatusChange: (id: string, status: TodoStatus) => void
  onDelete: (id: string) => void
}

const STATUS_LABELS: Record<TodoStatus, string> = {
  pending: 'Pending',
  in_progress: 'In Progress',
  completed: 'Completed',
}

const NEXT_STATUS: Record<TodoStatus, TodoStatus> = {
  pending: 'in_progress',
  in_progress: 'completed',
  completed: 'pending',
}

export function TodoItem({ todo, onStatusChange, onDelete }: TodoItemProps) {
  const handleStatusClick = () => {
    onStatusChange(todo.id, NEXT_STATUS[todo.status])
  }

  return (
    <div className={`todo-item ${todo.status}`}>
      <div className="todo-content">
        <h3 className="todo-title">{todo.title}</h3>
        {todo.description && <p className="todo-description">{todo.description}</p>}
      </div>

      <div className="todo-actions">
        <button
          className={`status-badge ${todo.status}`}
          onClick={handleStatusClick}
          title="Click to change status"
        >
          {STATUS_LABELS[todo.status]}
        </button>
        <button className="delete-btn" onClick={() => onDelete(todo.id)} title="Delete">
          x
        </button>
      </div>
    </div>
  )
}
