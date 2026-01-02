# ローカル開発環境

Docker Composeを使用したローカル開発環境です。

## 構成

| サービス       | ポート  | 説明                      |
|---------------|--------|--------------------------|
| frontend      | 5173   | React開発サーバー          |
| backend       | 8080   | FastAPI開発サーバー        |
| dynamodb      | 8000   | DynamoDB Local           |

## クイックスタート

```bash
# プロジェクトルートから実行
make local-up

# または local/ ディレクトリから
cd local
docker compose up -d
```

## URL

- **フロントエンド**: http://localhost:5173
- **バックエンドAPI**: http://localhost:8080
- **APIドキュメント**: http://localhost:8080/docs

## コマンド

```bash
# 起動
make local-up

# 停止
make local-down

# ログ確認
make local-logs

# イメージ再ビルド（依存関係更新時）
make local-build

# 完全削除（ボリューム含む）
make local-clean
```

## 本番環境との差分

| 項目                | ローカル              | 本番                      |
|--------------------|----------------------|--------------------------|
| DynamoDB           | DynamoDB Local       | AWS DynamoDB             |
| バックエンドホスト   | localhost:8080       | API Gateway + Lambda     |
| フロントエンドホスト | localhost:5173       | CloudFront + S3          |
| 認証                | 無効                 | Cognito                  |

## ホットリロード

- **バックエンド**: `backend/app/` 配下のファイル変更で自動リロード
- **フロントエンド**: `frontend/src/` 配下のファイル変更で自動リロード

## トラブルシューティング

### ポートが使用中の場合

```bash
# 使用中のポートを確認
lsof -i :5173
lsof -i :8080
lsof -i :8000

# 既存コンテナを削除
make local-clean
```

### DynamoDBテーブルの再作成

```bash
# 環境を完全リセット
make local-clean
make local-up
```

### ログの確認

```bash
# 全サービスのログ
make local-logs

# 特定サービスのログ
cd local && docker compose logs -f backend
cd local && docker compose logs -f frontend
```
