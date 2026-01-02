from datetime import datetime
from unittest.mock import MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.models.todo import Todo, TodoStats, TodoStatus
from app.services.todo_service import TodoService

client = TestClient(app)


@pytest.fixture
def mock_todo() -> Todo:
    return Todo(
        id="test-id-123",
        title="Test Todo",
        description="Test description",
        status=TodoStatus.PENDING,
        created_at=datetime.fromisoformat("2024-01-01T00:00:00+00:00"),
        updated_at=datetime.fromisoformat("2024-01-01T00:00:00+00:00"),
    )


@pytest.fixture
def mock_stats() -> TodoStats:
    return TodoStats(
        total=10,
        pending=3,
        in_progress=4,
        completed=3,
        completion_rate=30.0,
    )


class TestListTodos:
    @patch.object(TodoService, "list_all")
    def test_returns_empty_list(self, mock_list: MagicMock) -> None:
        mock_list.return_value = []
        response = client.get("/todos")
        assert response.status_code == 200
        assert response.json() == []

    @patch.object(TodoService, "list_all")
    def test_returns_todos(self, mock_list: MagicMock, mock_todo: Todo) -> None:
        mock_list.return_value = [mock_todo]
        response = client.get("/todos")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 1
        assert data[0]["id"] == "test-id-123"
        assert data[0]["title"] == "Test Todo"


class TestGetStats:
    @patch.object(TodoService, "get_stats")
    def test_returns_stats(self, mock_stats_fn: MagicMock, mock_stats: TodoStats) -> None:
        mock_stats_fn.return_value = mock_stats
        response = client.get("/todos/stats")
        assert response.status_code == 200
        data = response.json()
        assert data["total"] == 10
        assert data["completion_rate"] == 30.0


class TestCreateTodo:
    @patch.object(TodoService, "create")
    def test_creates_todo(self, mock_create: MagicMock, mock_todo: Todo) -> None:
        mock_create.return_value = mock_todo
        response = client.post("/todos", json={"title": "Test Todo"})
        assert response.status_code == 201
        data = response.json()
        assert data["title"] == "Test Todo"

    def test_validation_error_empty_title(self) -> None:
        response = client.post("/todos", json={"title": ""})
        assert response.status_code == 422


class TestGetTodo:
    @patch.object(TodoService, "get")
    def test_returns_todo(self, mock_get: MagicMock, mock_todo: Todo) -> None:
        mock_get.return_value = mock_todo
        response = client.get("/todos/test-id-123")
        assert response.status_code == 200
        assert response.json()["id"] == "test-id-123"

    @patch.object(TodoService, "get")
    def test_not_found(self, mock_get: MagicMock) -> None:
        mock_get.return_value = None
        response = client.get("/todos/nonexistent")
        assert response.status_code == 404


class TestUpdateTodo:
    @patch.object(TodoService, "update")
    def test_updates_todo(self, mock_update: MagicMock, mock_todo: Todo) -> None:
        updated = mock_todo.model_copy(update={"title": "Updated"})
        mock_update.return_value = updated
        response = client.patch("/todos/test-id-123", json={"title": "Updated"})
        assert response.status_code == 200

    @patch.object(TodoService, "update")
    def test_not_found(self, mock_update: MagicMock) -> None:
        mock_update.return_value = None
        response = client.patch("/todos/nonexistent", json={"title": "Updated"})
        assert response.status_code == 404


class TestDeleteTodo:
    @patch.object(TodoService, "delete")
    def test_deletes_todo(self, mock_delete: MagicMock) -> None:
        mock_delete.return_value = True
        response = client.delete("/todos/test-id-123")
        assert response.status_code == 204

    @patch.object(TodoService, "delete")
    def test_not_found(self, mock_delete: MagicMock) -> None:
        mock_delete.return_value = False
        response = client.delete("/todos/nonexistent")
        assert response.status_code == 404
