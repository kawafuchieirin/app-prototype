#!/bin/bash
set -e

COGNITO_ENDPOINT="http://localhost:9229"
POOL_NAME="app-prototype-local"
CLIENT_NAME="app-prototype-client"
TEST_USER_EMAIL="test@example.com"
TEST_USER_PASSWORD="Test1234!"

echo "=== Cognito Local 初期化 ==="

# ユーザープール作成
echo "ユーザープールを作成中..."
POOL_ID=$(aws cognito-idp create-user-pool \
  --endpoint-url $COGNITO_ENDPOINT \
  --pool-name $POOL_NAME \
  --auto-verified-attributes email \
  --username-attributes email \
  --policies '{"PasswordPolicy":{"MinimumLength":8,"RequireUppercase":true,"RequireLowercase":true,"RequireNumbers":true,"RequireSymbols":false}}' \
  --query 'UserPool.Id' \
  --output text)

echo "ユーザープールID: $POOL_ID"

# ユーザープールクライアント作成
echo "ユーザープールクライアントを作成中..."
CLIENT_ID=$(aws cognito-idp create-user-pool-client \
  --endpoint-url $COGNITO_ENDPOINT \
  --user-pool-id $POOL_ID \
  --client-name $CLIENT_NAME \
  --explicit-auth-flows ADMIN_NO_SRP_AUTH USER_PASSWORD_AUTH \
  --query 'UserPoolClient.ClientId' \
  --output text)

echo "クライアントID: $CLIENT_ID"

# テストユーザー作成
echo "テストユーザーを作成中..."
aws cognito-idp admin-create-user \
  --endpoint-url $COGNITO_ENDPOINT \
  --user-pool-id $POOL_ID \
  --username $TEST_USER_EMAIL \
  --user-attributes Name=email,Value=$TEST_USER_EMAIL Name=email_verified,Value=true \
  --temporary-password $TEST_USER_PASSWORD \
  --message-action SUPPRESS

# パスワードを永続化
aws cognito-idp admin-set-user-password \
  --endpoint-url $COGNITO_ENDPOINT \
  --user-pool-id $POOL_ID \
  --username $TEST_USER_EMAIL \
  --password $TEST_USER_PASSWORD \
  --permanent

echo ""
echo "=== 初期化完了 ==="
echo ""
echo "設定情報:"
echo "  COGNITO_ENDPOINT: $COGNITO_ENDPOINT"
echo "  USER_POOL_ID: $POOL_ID"
echo "  CLIENT_ID: $CLIENT_ID"
echo ""
echo "テストユーザー:"
echo "  Email: $TEST_USER_EMAIL"
echo "  Password: $TEST_USER_PASSWORD"
echo ""

# 環境変数ファイル作成
cat > /Users/kawabuchieirin/Desktop/project/app-prototype/local/.env.local <<EOF
# Cognito Local 設定
COGNITO_ENDPOINT=$COGNITO_ENDPOINT
COGNITO_USER_POOL_ID=$POOL_ID
COGNITO_CLIENT_ID=$CLIENT_ID

# DynamoDB Local 設定
DYNAMODB_ENDPOINT_URL=http://localhost:8000
DYNAMODB_TABLE_NAME=app-prototype-local

# テストユーザー
TEST_USER_EMAIL=$TEST_USER_EMAIL
TEST_USER_PASSWORD=$TEST_USER_PASSWORD
EOF

echo ".env.local ファイルを作成しました"
