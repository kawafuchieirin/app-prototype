export type TodoStatus = 'pending' | 'in_progress' | 'completed'

export interface Todo {
  id: string
  title: string
  description: string | null
  status: TodoStatus
  created_at: string
  updated_at: string
}

export interface TodoCreate {
  title: string
  description?: string
  status?: TodoStatus
}

export interface TodoUpdate {
  title?: string
  description?: string
  status?: TodoStatus
}

export interface TodoStats {
  total: number
  pending: number
  in_progress: number
  completed: number
  completion_rate: number
}
