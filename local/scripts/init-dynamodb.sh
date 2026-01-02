#!/bin/bash
set -e

DYNAMODB_ENDPOINT="http://localhost:8000"
TABLE_NAME="app-prototype-local"

echo "=== DynamoDB Local 初期化 ==="

# テーブル存在確認
if aws dynamodb describe-table \
  --endpoint-url $DYNAMODB_ENDPOINT \
  --table-name $TABLE_NAME \
  --region ap-northeast-1 2>/dev/null; then
  echo "テーブル '$TABLE_NAME' は既に存在します"
else
  echo "テーブルを作成中..."
  aws dynamodb create-table \
    --endpoint-url $DYNAMODB_ENDPOINT \
    --table-name $TABLE_NAME \
    --attribute-definitions \
      AttributeName=PK,AttributeType=S \
      AttributeName=SK,AttributeType=S \
    --key-schema \
      AttributeName=PK,KeyType=HASH \
      AttributeName=SK,KeyType=RANGE \
    --billing-mode PAY_PER_REQUEST \
    --region ap-northeast-1

  echo "テーブル '$TABLE_NAME' を作成しました"
fi

echo ""
echo "=== 初期化完了 ==="
