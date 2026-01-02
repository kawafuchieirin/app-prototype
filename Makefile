# シェルとPATHの設定
SHELL := /bin/bash
export PATH := /opt/homebrew/bin:/usr/local/bin:$(PATH)

.PHONY: help install install-frontend install-backend dev dev-frontend dev-backend dev-local local-up local-down local-init local-logs test test-frontend test-backend lint lint-frontend lint-backend format build build-frontend build-backend clean tf-init tf-plan tf-apply tf-destroy pre-commit-install pre-commit-run deploy deploy-backend deploy-frontend deploy-infra

# ==============================
# 設定
# ==============================
AWS_REGION ?= ap-northeast-1
ECR_REPO = 412420079063.dkr.ecr.$(AWS_REGION).amazonaws.com/app-prototype-api-dev
LAMBDA_FUNCTION = app-prototype-api-dev
S3_BUCKET = app-prototype-frontend-dev
CLOUDFRONT_ID = E3MKYSY7TC8WOW
API_URL = https://i7yz3ihjzj.execute-api.$(AWS_REGION).amazonaws.com
DYNAMODB_TABLE = app-prototype-dev

# デフォルトターゲット
help:
	@echo "利用可能なコマンド:"
	@echo ""
	@echo "  セットアップ:"
	@echo "    make install            - 全ての依存関係をインストール"
	@echo "    make install-frontend   - フロントエンドの依存関係をインストール"
	@echo "    make install-backend    - バックエンドの依存関係をインストール"
	@echo "    make pre-commit-install - pre-commitフックをインストール"
	@echo ""
	@echo "  ローカル開発（AWS使用）:"
	@echo "    make dev                - フロントエンド+バックエンドを同時起動"
	@echo "    make dev-frontend       - フロントエンドのみ (localhost:5173)"
	@echo "    make dev-backend        - バックエンドのみ (localhost:8000)"
	@echo ""
	@echo "  ローカル開発（Docker使用）:"
	@echo "    make local-up           - Cognito/DynamoDB Localを起動"
	@echo "    make local-init         - ローカル環境を初期化"
	@echo "    make dev-local          - ローカル環境でフロント+バックエンド起動"
	@echo "    make local-down         - Dockerコンテナを停止"
	@echo "    make local-logs         - Dockerログを表示"
	@echo ""
	@echo "  テスト:"
	@echo "    make test               - 全テストを実行"
	@echo "    make test-frontend      - フロントエンドのテストを実行"
	@echo "    make test-backend       - バックエンドのテストを実行"
	@echo ""
	@echo "  コード品質:"
	@echo "    make lint               - 全プロジェクトのリントを実行"
	@echo "    make format             - コードフォーマットを実行"
	@echo ""
	@echo "  AWSデプロイ:"
	@echo "    make deploy             - バックエンド+フロントエンドをAWSにデプロイ"
	@echo "    make deploy-backend     - バックエンドをECR/Lambdaにデプロイ"
	@echo "    make deploy-frontend    - フロントエンドをS3/CloudFrontにデプロイ"
	@echo "    make deploy-infra       - Terraformでインフラをデプロイ"
	@echo ""
	@echo "  Terraform:"
	@echo "    make tf-init            - Terraformを初期化"
	@echo "    make tf-plan            - Terraformプランを表示"
	@echo "    make tf-apply           - Terraformを適用"
	@echo "    make tf-destroy         - インフラを破棄"
	@echo ""
	@echo "  その他:"
	@echo "    make build              - 全プロジェクトをビルド"
	@echo "    make clean              - ビルド成果物を削除"

# ==============================
# セットアップ
# ==============================
install: install-frontend install-backend pre-commit-install

install-frontend:
	cd frontend && npm install

install-backend:
	cd backend && poetry install

pre-commit-install:
	pre-commit install || true

# ==============================
# ローカル開発
# ==============================
dev:
	@echo "🚀 ローカル開発環境を起動中..."
	@echo "  バックエンド: http://localhost:8000"
	@echo "  フロントエンド: http://localhost:5173"
	@echo ""
	@echo "停止するには Ctrl+C を押してください"
	@trap 'kill 0' EXIT; \
	(cd backend && DYNAMODB_TABLE_NAME=$(DYNAMODB_TABLE) poetry run uvicorn app.main:app --reload --port 8000) & \
	(cd frontend && npm run dev) & \
	wait

dev-frontend:
	cd frontend && npm run dev

dev-backend:
	cd backend && DYNAMODB_TABLE_NAME=$(DYNAMODB_TABLE) poetry run uvicorn app.main:app --reload --port 8000

# ==============================
# ローカル環境 (Docker: Cognito/DynamoDB Local)
# ==============================
local-up:
	cd local && docker compose up -d
	@echo "Cognito Local: http://localhost:9229"
	@echo "DynamoDB Local: http://localhost:8000"

local-down:
	cd local && docker compose down

local-logs:
	cd local && docker compose logs -f

local-init: local-up
	@echo "コンテナが起動するまで待機中..."
	@sleep 3
	./local/scripts/init-dynamodb.sh
	./local/scripts/init-cognito.sh

dev-local:
	@if [ ! -f local/.env.local ]; then \
		echo "ローカル環境が初期化されていません。make local-init を実行してください。"; \
		exit 1; \
	fi
	@echo "🚀 ローカル開発環境を起動中（Docker使用）..."
	@echo "  バックエンド: http://localhost:8000"
	@echo "  フロントエンド: http://localhost:5173"
	@echo "  Cognito Local: http://localhost:9229"
	@echo "  DynamoDB Local: http://localhost:8000"
	@echo ""
	@echo "停止するには Ctrl+C を押してください"
	@source local/.env.local && trap 'kill 0' EXIT; \
	(cd backend && \
		DYNAMODB_ENDPOINT_URL=http://localhost:8000 \
		DYNAMODB_TABLE_NAME=app-prototype-local \
		COGNITO_ENDPOINT_URL=http://localhost:9229 \
		COGNITO_USER_POOL_ID=$$COGNITO_USER_POOL_ID \
		COGNITO_CLIENT_ID=$$COGNITO_CLIENT_ID \
		poetry run uvicorn app.main:app --reload --port 8001) & \
	(cd frontend && VITE_API_URL=http://localhost:8001 npm run dev) & \
	wait

# ==============================
# テスト
# ==============================
test: test-frontend test-backend

test-frontend:
	cd frontend && npm test -- --run

test-backend:
	cd backend && poetry run pytest

# ==============================
# コード品質
# ==============================
lint: lint-frontend lint-backend

lint-frontend:
	cd frontend && npm run lint

lint-backend:
	cd backend && poetry run ruff check .
	cd backend && poetry run mypy .

format:
	cd frontend && npm run format
	cd backend && poetry run ruff format .

pre-commit-run:
	pre-commit run --all-files

# ==============================
# ビルド
# ==============================
build: build-frontend build-backend

build-frontend:
	cd frontend && npm run build

build-backend:
	cd backend && poetry build

# ==============================
# AWSデプロイ
# ==============================
deploy: deploy-backend deploy-frontend
	@echo ""
	@echo "✅ デプロイ完了!"
	@echo "  フロントエンド: https://d3qvrkx1xlvdqo.cloudfront.net"
	@echo "  API: $(API_URL)"

deploy-backend:
	@echo "=== バックエンドをデプロイ ==="
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REPO)
	cd backend && docker build -t $(ECR_REPO):latest .
	docker push $(ECR_REPO):latest
	aws lambda update-function-code --function-name $(LAMBDA_FUNCTION) --image-uri $(ECR_REPO):latest --region $(AWS_REGION)
	aws lambda wait function-updated --function-name $(LAMBDA_FUNCTION) --region $(AWS_REGION)
	@echo "✅ バックエンドデプロイ完了!"

deploy-frontend:
	@echo "=== フロントエンドをデプロイ ==="
	cd frontend && VITE_API_URL=$(API_URL) npm run build
	aws s3 sync frontend/dist/ s3://$(S3_BUCKET) --delete --region $(AWS_REGION)
	aws cloudfront create-invalidation --distribution-id $(CLOUDFRONT_ID) --paths "/*" --region $(AWS_REGION)
	@echo "✅ フロントエンドデプロイ完了!"

deploy-infra:
	@echo "=== インフラをデプロイ ==="
	cd infrastructure/terraform && terraform init -upgrade && terraform apply -auto-approve

# ==============================
# Terraform
# ==============================
tf-init:
	cd infrastructure/terraform && terraform init

tf-plan:
	cd infrastructure/terraform && terraform plan

tf-apply:
	cd infrastructure/terraform && terraform apply

tf-destroy:
	cd infrastructure/terraform && terraform destroy

# ==============================
# クリーンアップ
# ==============================
clean:
	rm -rf frontend/dist frontend/build frontend/node_modules/.cache
	rm -rf backend/dist backend/build backend/__pycache__
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
