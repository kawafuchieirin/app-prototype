from datetime import datetime
from enum import Enum

from pydantic import BaseModel, Field


class TodoStatus(str, Enum):
    PENDING = "pending"
    IN_PROGRESS = "in_progress"
    COMPLETED = "completed"


class TodoBase(BaseModel):
    title: str = Field(..., min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=1000)
    status: TodoStatus = TodoStatus.PENDING


class TodoCreate(TodoBase):
    pass


class TodoUpdate(BaseModel):
    title: str | None = Field(default=None, min_length=1, max_length=200)
    description: str | None = Field(default=None, max_length=1000)
    status: TodoStatus | None = None


class Todo(TodoBase):
    id: str
    created_at: datetime
    updated_at: datetime


class TodoStats(BaseModel):
    total: int
    pending: int
    in_progress: int
    completed: int
    completion_rate: float
