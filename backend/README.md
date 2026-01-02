# Backend

FastAPI + Python 3.14 で構築されたバックエンドAPI。AWS Lambda上で動作。

## 技術スタック

- **Python 3.14**
- **FastAPI** - 高速なWebフレームワーク
- **Poetry** - 依存関係管理
- **Mangum** - AWS Lambda ASGI アダプター
- **Pydantic** - データバリデーション
- **boto3** - AWS SDK

### 開発ツール

- **pytest** - テストフレームワーク
- **Ruff** - リンター & フォーマッター
- **mypy** - 静的型チェック

## ディレクトリ構成

```
backend/
├── app/
│   ├── __init__.py
│   ├── main.py          # FastAPIアプリケーション & Lambdaハンドラー
│   ├── config.py        # 環境設定
│   └── routers/         # APIルーター
│       ├── __init__.py
│       └── health.py    # ヘルスチェックエンドポイント
├── tests/
│   ├── __init__.py
│   └── test_health.py   # テスト
└── pyproject.toml       # プロジェクト設定 & 依存関係
```

## セットアップ

### 前提条件

- Python 3.14+
- Poetry

### インストール

```bash
# 依存関係のインストール
poetry install

# 仮想環境に入る
poetry shell
```

## 開発

### 開発サーバー起動

```bash
# uvicornで起動 (ホットリロード有効)
poetry run uvicorn app.main:app --reload --port 8000

# または Makefile から
make dev-backend
```

APIドキュメント: http://localhost:8000/docs

### テスト実行

```bash
# 全テスト実行
poetry run pytest

# カバレッジ付き
poetry run pytest --cov=app --cov-report=term-missing

# 特定のテストファイル
poetry run pytest tests/test_health.py -v
```

### リント & フォーマット

```bash
# リントチェック
poetry run ruff check .

# 自動修正
poetry run ruff check . --fix

# フォーマット
poetry run ruff format .

# 型チェック
poetry run mypy .
```

## API エンドポイント

| Method | Path      | 説明               |
|--------|-----------|-------------------|
| GET    | /         | ルート             |
| GET    | /health   | ヘルスチェック      |
| GET    | /docs     | OpenAPI ドキュメント |

## 環境変数

| 変数名              | 説明                    | デフォルト値          |
|--------------------|------------------------|---------------------|
| DEBUG              | デバッグモード            | false               |
| AWS_REGION         | AWSリージョン            | ap-northeast-1      |
| DYNAMODB_TABLE_NAME| DynamoDBテーブル名       | app-prototype       |
| ALLOWED_ORIGINS    | CORS許可オリジン         | localhost:5173,3000 |

## デプロイ

### Lambda パッケージング

```bash
# 依存関係のみインストール
poetry install --only main

# パッケージ作成
mkdir -p package
cp -r app package/
cd .venv/lib/python3.14/site-packages
cp -r * ../../../../package/
cd ../../../../package
zip -r ../lambda.zip .
```

### AWS Lambda へデプロイ

```bash
aws lambda update-function-code \
  --function-name app-prototype-api-dev \
  --zip-file fileb://lambda.zip
```

## 新しいルーターの追加

1. `app/routers/` に新しいファイルを作成:

```python
# app/routers/users.py
from fastapi import APIRouter

router = APIRouter(prefix="/users", tags=["users"])

@router.get("")
async def list_users() -> list[dict]:
    return []
```

2. `app/main.py` でインポート:

```python
from app.routers import health, users

app.include_router(health.router)
app.include_router(users.router)
```

## DynamoDB アクセス

```python
import boto3
from app.config import settings

dynamodb = boto3.resource("dynamodb", region_name=settings.aws_region)
table = dynamodb.Table(settings.dynamodb_table_name)

# アイテム取得
response = table.get_item(Key={"PK": "USER#123", "SK": "PROFILE"})

# アイテム保存
table.put_item(Item={"PK": "USER#123", "SK": "PROFILE", "name": "John"})
```
