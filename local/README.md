# ローカル開発環境

AWS サービスをローカルでエミュレートして開発するための環境です。

## 概要

| サービス | ローカル | AWS |
|----------|----------|-----|
| 認証 | cognito-local (port 9229) | AWS Cognito |
| データベース | DynamoDB Local (port 8000) | AWS DynamoDB |

## 前提条件

- Docker Desktop
- Node.js 22+
- Python 3.14+
- Poetry

## クイックスタート

```bash
# プロジェクトルートから実行

# 1. 依存関係のインストール
make install

# 2. ローカル環境を初期化（初回のみ）
make local-init

# 3. 開発サーバーを起動
make dev-local
```

## ディレクトリ構成

```
local/
├── docker-compose.yml   # Docker サービス定義
├── .env.local           # 生成された環境変数（gitignore対象）
├── scripts/
│   ├── init-all.sh      # 全初期化を実行
│   ├── init-cognito.sh  # Cognito ユーザープール作成
│   ├── init-dynamodb.sh # DynamoDB テーブル作成
│   └── init-dynamodb.py # テーブル作成スクリプト
└── README.md            # このファイル
```

## サービス詳細

### cognito-local

[jagregory/cognito-local](https://github.com/jagregory/cognito-local) を使用。

```yaml
# docker-compose.yml
services:
  cognito-local:
    image: jagregory/cognito-local:latest
    ports:
      - "9229:9229"
```

### DynamoDB Local

```yaml
# docker-compose.yml
services:
  dynamodb-local:
    image: amazon/dynamodb-local:latest
    ports:
      - "8000:8000"
    command: "-jar DynamoDBLocal.jar -sharedDb -inMemory"
```

## 環境変数

初期化スクリプトが `.env.local` を自動生成します：

```bash
# Cognito Local 設定
COGNITO_ENDPOINT_URL=http://127.0.0.1:9229
COGNITO_USER_POOL_ID=local_XXXXXXXX
COGNITO_CLIENT_ID=XXXXXXXXXXXXXXX

# DynamoDB Local 設定
DYNAMODB_ENDPOINT_URL=http://127.0.0.1:8000
DYNAMODB_TABLE_NAME=app-prototype-local

# テストユーザー
TEST_USER_EMAIL=test@example.com
TEST_USER_PASSWORD=Test1234!
```

## テストユーザー

初期化時に以下のテストユーザーが作成されます：

| 項目 | 値 |
|------|-----|
| Email | test@example.com |
| Password | Test1234! |

## コマンド一覧

```bash
# Docker コンテナの起動
docker compose -f local/docker-compose.yml up -d

# Docker コンテナの停止
docker compose -f local/docker-compose.yml down

# コンテナの状態確認
docker compose -f local/docker-compose.yml ps

# ログの確認
docker compose -f local/docker-compose.yml logs -f

# 全データを削除して再初期化
docker compose -f local/docker-compose.yml down -v
make local-init
```

## トラブルシューティング

### ポートが使用中

```bash
# 使用中のポートを確認
lsof -i :9229
lsof -i :8000

# プロセスを終了
kill -9 <PID>
```

### 認証エラー

```bash
# Cognito データをリセット
docker compose -f local/docker-compose.yml down -v
make local-init
```

### DynamoDB テーブルが見つからない

```bash
# テーブル一覧を確認
aws dynamodb list-tables --endpoint-url http://127.0.0.1:8000

# テーブルを再作成
bash local/scripts/init-dynamodb.sh
```

## AWS環境との違い

ローカル環境とAWS環境は**同一のアプリケーションコード**を使用します。
違いは環境変数のみ：

| 環境変数 | ローカル | AWS |
|----------|----------|-----|
| `VITE_COGNITO_ENDPOINT` | `http://127.0.0.1:9229` | 未設定 |
| `COGNITO_ENDPOINT_URL` | `http://127.0.0.1:9229` | 未設定 |
| `DYNAMODB_ENDPOINT_URL` | `http://127.0.0.1:8000` | 未設定 |

エンドポイントが未設定の場合、AWSのデフォルトエンドポイントが使用されます。
