#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_DIR="$(dirname "$SCRIPT_DIR")"

echo "=== ローカル環境を初期化中 ==="
echo ""

# Dockerコンテナが起動しているか確認
if ! docker ps | grep -q cognito-local; then
  echo "Dockerコンテナを起動中..."
  cd "$LOCAL_DIR" && docker compose up -d
  echo "コンテナが起動するまで待機中..."
  sleep 5
fi

# DynamoDB初期化
echo ""
bash "$SCRIPT_DIR/init-dynamodb.sh"

# Cognito初期化
echo ""
bash "$SCRIPT_DIR/init-cognito.sh"

echo ""
echo "=== すべての初期化が完了しました ==="
echo ""
echo "ローカル開発を開始するには:"
echo "  make dev-local"
