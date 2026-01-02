import uuid
from datetime import UTC, datetime
from typing import TYPE_CHECKING

import boto3
from boto3.dynamodb.conditions import Key

from app.config import settings
from app.models.todo import Todo, TodoCreate, TodoStats, TodoStatus, TodoUpdate

if TYPE_CHECKING:
    from mypy_boto3_dynamodb.service_resource import Table


class TodoService:
    def __init__(self) -> None:
        self._table: Table | None = None

    @property
    def table(self) -> "Table":
        if self._table is None:
            # ローカル環境ではエンドポイントURLを指定
            if settings.dynamodb_endpoint_url:
                dynamodb = boto3.resource(
                    "dynamodb",
                    region_name=settings.aws_region,
                    endpoint_url=settings.dynamodb_endpoint_url,
                )
            else:
                dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
            self._table = dynamodb.Table(settings.dynamodb_table_name)
        return self._table

    def _generate_id(self) -> str:
        return str(uuid.uuid4())

    def _now(self) -> datetime:
        return datetime.now(UTC)

    def create(self, todo_create: TodoCreate) -> Todo:
        now = self._now()
        todo_id = self._generate_id()

        item = {
            "PK": "TODO",
            "SK": f"TODO#{todo_id}",
            "id": todo_id,
            "title": todo_create.title,
            "description": todo_create.description,
            "status": todo_create.status.value,
            "created_at": now.isoformat(),
            "updated_at": now.isoformat(),
        }

        self.table.put_item(Item=item)

        return Todo(
            id=todo_id,
            title=todo_create.title,
            description=todo_create.description,
            status=todo_create.status,
            created_at=now,
            updated_at=now,
        )

    def get(self, todo_id: str) -> Todo | None:
        response = self.table.get_item(Key={"PK": "TODO", "SK": f"TODO#{todo_id}"})

        item = response.get("Item")
        if not item:
            return None

        return self._item_to_todo(item)

    def list_all(self) -> list[Todo]:
        response = self.table.query(KeyConditionExpression=Key("PK").eq("TODO"))

        items = response.get("Items", [])
        return [self._item_to_todo(item) for item in items]

    def update(self, todo_id: str, todo_update: TodoUpdate) -> Todo | None:
        existing = self.get(todo_id)
        if not existing:
            return None

        now = self._now()
        update_expressions: list[str] = ["updated_at = :updated_at"]
        expression_values: dict[str, str] = {":updated_at": now.isoformat()}

        if todo_update.title is not None:
            update_expressions.append("title = :title")
            expression_values[":title"] = todo_update.title

        if todo_update.description is not None:
            update_expressions.append("description = :description")
            expression_values[":description"] = todo_update.description

        if todo_update.status is not None:
            update_expressions.append("#status = :status")
            expression_values[":status"] = todo_update.status.value

        update_expression = "SET " + ", ".join(update_expressions)

        expression_names = {}
        if todo_update.status is not None:
            expression_names["#status"] = "status"

        update_kwargs: dict[str, object] = {
            "Key": {"PK": "TODO", "SK": f"TODO#{todo_id}"},
            "UpdateExpression": update_expression,
            "ExpressionAttributeValues": expression_values,
            "ReturnValues": "ALL_NEW",
        }

        if expression_names:
            update_kwargs["ExpressionAttributeNames"] = expression_names

        response = self.table.update_item(**update_kwargs)  # type: ignore[arg-type]

        return self._item_to_todo(response["Attributes"])

    def delete(self, todo_id: str) -> bool:
        existing = self.get(todo_id)
        if not existing:
            return False

        self.table.delete_item(Key={"PK": "TODO", "SK": f"TODO#{todo_id}"})
        return True

    def get_stats(self) -> TodoStats:
        todos = self.list_all()
        total = len(todos)

        pending = sum(1 for t in todos if t.status == TodoStatus.PENDING)
        in_progress = sum(1 for t in todos if t.status == TodoStatus.IN_PROGRESS)
        completed = sum(1 for t in todos if t.status == TodoStatus.COMPLETED)

        completion_rate = (completed / total * 100) if total > 0 else 0.0

        return TodoStats(
            total=total,
            pending=pending,
            in_progress=in_progress,
            completed=completed,
            completion_rate=round(completion_rate, 1),
        )

    def _item_to_todo(self, item: dict[str, object]) -> Todo:
        return Todo(
            id=str(item["id"]),
            title=str(item["title"]),
            description=str(item["description"]) if item.get("description") else None,
            status=TodoStatus(str(item["status"])),
            created_at=datetime.fromisoformat(str(item["created_at"])),
            updated_at=datetime.fromisoformat(str(item["updated_at"])),
        )


todo_service = TodoService()
