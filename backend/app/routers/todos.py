from fastapi import APIRouter, HTTPException

from app.models.todo import Todo, TodoCreate, TodoStats, TodoUpdate
from app.services.todo_service import todo_service

router = APIRouter(prefix="/todos", tags=["todos"])


@router.get("", response_model=list[Todo])
async def list_todos() -> list[Todo]:
    """全てのToDoを取得"""
    return todo_service.list_all()


@router.get("/stats", response_model=TodoStats)
async def get_stats() -> TodoStats:
    """ToDoの統計情報を取得"""
    return todo_service.get_stats()


@router.post("", response_model=Todo, status_code=201)
async def create_todo(todo_create: TodoCreate) -> Todo:
    """新しいToDoを作成"""
    return todo_service.create(todo_create)


@router.get("/{todo_id}", response_model=Todo)
async def get_todo(todo_id: str) -> Todo:
    """特定のToDoを取得"""
    todo = todo_service.get(todo_id)
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    return todo


@router.patch("/{todo_id}", response_model=Todo)
async def update_todo(todo_id: str, todo_update: TodoUpdate) -> Todo:
    """ToDoを更新"""
    todo = todo_service.update(todo_id, todo_update)
    if not todo:
        raise HTTPException(status_code=404, detail="Todo not found")
    return todo


@router.delete("/{todo_id}", status_code=204)
async def delete_todo(todo_id: str) -> None:
    """ToDoを削除"""
    if not todo_service.delete(todo_id):
        raise HTTPException(status_code=404, detail="Todo not found")
