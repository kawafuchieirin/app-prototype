#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_DIR="$(dirname "$(dirname "$SCRIPT_DIR")")"

export DYNAMODB_ENDPOINT_URL="http://127.0.0.1:8000"
export DYNAMODB_TABLE_NAME="app-prototype-local"
export AWS_ACCESS_KEY_ID="dummy"
export AWS_SECRET_ACCESS_KEY="dummy"
export AWS_DEFAULT_REGION="ap-northeast-1"

cd "$PROJECT_DIR/backend"
poetry run python "$SCRIPT_DIR/init-dynamodb.py"
