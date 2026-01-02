#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
LOCAL_DIR="$(dirname "$SCRIPT_DIR")"

COGNITO_ENDPOINT="http://127.0.0.1:9229"
POOL_NAME="app-prototype-local"
CLIENT_NAME="app-prototype-client"
TEST_USER_EMAIL="test@example.com"
TEST_USER_PASSWORD="Test1234!"

echo "=== Cognito Local 初期化 ==="

# AWS CLIの代わりにcurlでREST APIを使用
# ユーザープール作成
echo "ユーザープールを作成中..."
POOL_RESPONSE=$(curl -s -X POST "$COGNITO_ENDPOINT" \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.CreateUserPool" \
  -d "{
    \"PoolName\": \"$POOL_NAME\",
    \"AutoVerifiedAttributes\": [\"email\"],
    \"UsernameAttributes\": [\"email\"],
    \"Policies\": {
      \"PasswordPolicy\": {
        \"MinimumLength\": 8,
        \"RequireUppercase\": true,
        \"RequireLowercase\": true,
        \"RequireNumbers\": true,
        \"RequireSymbols\": false
      }
    }
  }")

POOL_ID=$(echo "$POOL_RESPONSE" | grep -o '"Id":"[^"]*"' | head -1 | cut -d'"' -f4)
echo "ユーザープールID: $POOL_ID"

# ユーザープールクライアント作成
echo "ユーザープールクライアントを作成中..."
CLIENT_RESPONSE=$(curl -s -X POST "$COGNITO_ENDPOINT" \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.CreateUserPoolClient" \
  -d "{
    \"UserPoolId\": \"$POOL_ID\",
    \"ClientName\": \"$CLIENT_NAME\",
    \"ExplicitAuthFlows\": [\"ADMIN_NO_SRP_AUTH\", \"USER_PASSWORD_AUTH\"]
  }")

CLIENT_ID=$(echo "$CLIENT_RESPONSE" | grep -o '"ClientId":"[^"]*"' | cut -d'"' -f4)
echo "クライアントID: $CLIENT_ID"

# テストユーザー作成
echo "テストユーザーを作成中..."
curl -s -X POST "$COGNITO_ENDPOINT" \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.AdminCreateUser" \
  -d "{
    \"UserPoolId\": \"$POOL_ID\",
    \"Username\": \"$TEST_USER_EMAIL\",
    \"UserAttributes\": [
      {\"Name\": \"email\", \"Value\": \"$TEST_USER_EMAIL\"},
      {\"Name\": \"email_verified\", \"Value\": \"true\"}
    ],
    \"TemporaryPassword\": \"$TEST_USER_PASSWORD\",
    \"MessageAction\": \"SUPPRESS\"
  }" > /dev/null

# パスワードを永続化
curl -s -X POST "$COGNITO_ENDPOINT" \
  -H "Content-Type: application/x-amz-json-1.1" \
  -H "X-Amz-Target: AWSCognitoIdentityProviderService.AdminSetUserPassword" \
  -d "{
    \"UserPoolId\": \"$POOL_ID\",
    \"Username\": \"$TEST_USER_EMAIL\",
    \"Password\": \"$TEST_USER_PASSWORD\",
    \"Permanent\": true
  }" > /dev/null

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
cat > "$LOCAL_DIR/.env.local" <<EOF
# Cognito Local 設定
COGNITO_ENDPOINT_URL=$COGNITO_ENDPOINT
COGNITO_USER_POOL_ID=$POOL_ID
COGNITO_CLIENT_ID=$CLIENT_ID

# DynamoDB Local 設定
DYNAMODB_ENDPOINT_URL=http://127.0.0.1:8000
DYNAMODB_TABLE_NAME=app-prototype-local

# テストユーザー
TEST_USER_EMAIL=$TEST_USER_EMAIL
TEST_USER_PASSWORD=$TEST_USER_PASSWORD
EOF

echo ".env.local ファイルを作成しました"
