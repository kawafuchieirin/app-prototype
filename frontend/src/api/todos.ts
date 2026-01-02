import type { Todo, TodoCreate, TodoStats, TodoUpdate } from '../types/todo'
import { fetchApi } from './client'

export async function getTodos(): Promise<Todo[]> {
  return fetchApi<Todo[]>('/todos')
}

export async function getTodoStats(): Promise<TodoStats> {
  return fetchApi<TodoStats>('/todos/stats')
}

export async function createTodo(todo: TodoCreate): Promise<Todo> {
  return fetchApi<Todo>('/todos', {
    method: 'POST',
    body: JSON.stringify(todo),
  })
}

export async function updateTodo(id: string, todo: TodoUpdate): Promise<Todo> {
  return fetchApi<Todo>(`/todos/${id}`, {
    method: 'PATCH',
    body: JSON.stringify(todo),
  })
}

export async function deleteTodo(id: string): Promise<void> {
  return fetchApi<void>(`/todos/${id}`, {
    method: 'DELETE',
  })
}
