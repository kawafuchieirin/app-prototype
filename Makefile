.PHONY: help install install-frontend install-backend dev dev-frontend dev-backend test test-frontend test-backend lint lint-frontend lint-backend format build build-frontend build-backend clean tf-init tf-plan tf-apply tf-destroy pre-commit-install pre-commit-run local-up local-down local-logs local-build local-clean deploy deploy-backend deploy-frontend deploy-infra

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
	@echo "  開発:"
	@echo "    make dev                - 全サービスを開発モードで起動"
	@echo "    make dev-frontend       - フロントエンドを開発モードで起動"
	@echo "    make dev-backend        - バックエンドを開発モードで起動"
	@echo ""
	@echo "  テスト:"
	@echo "    make test               - 全テストを実行"
	@echo "    make test-frontend      - フロントエンドのテストを実行"
	@echo "    make test-backend       - バックエンドのテストを実行"
	@echo ""
	@echo "  コード品質:"
	@echo "    make lint               - 全プロジェクトのリントを実行"
	@echo "    make lint-frontend      - フロントエンドのリントを実行"
	@echo "    make lint-backend       - バックエンドのリントを実行"
	@echo "    make format             - コードフォーマットを実行"
	@echo "    make pre-commit-run     - pre-commitを手動実行"
	@echo ""
	@echo "  ビルド:"
	@echo "    make build              - 全プロジェクトをビルド"
	@echo "    make build-frontend     - フロントエンドをビルド"
	@echo "    make build-backend      - バックエンドをビルド"
	@echo ""
	@echo "  Terraform:"
	@echo "    make tf-init            - Terraformを初期化"
	@echo "    make tf-plan            - Terraformプランを表示"
	@echo "    make tf-apply           - Terraformを適用"
	@echo "    make tf-destroy         - インフラを破棄"
	@echo ""
	@echo "  デプロイ:"
	@echo "    make deploy             - バックエンドとフロントエンドをデプロイ"
	@echo "    make deploy-backend     - バックエンドをECR/Lambdaにデプロイ"
	@echo "    make deploy-frontend    - フロントエンドをS3/CloudFrontにデプロイ"
	@echo "    make deploy-infra       - Terraformでインフラをデプロイ"
	@echo ""
	@echo "  ローカル環境 (Docker):"
	@echo "    make local-up           - Docker環境を起動"
	@echo "    make local-down         - Docker環境を停止"
	@echo "    make local-logs         - ログを表示"
	@echo "    make local-build        - イメージを再ビルド"
	@echo "    make local-clean        - Docker環境を完全削除"
	@echo ""
	@echo "  その他:"
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
	pre-commit install

# ==============================
# 開発
# ==============================
dev:
	@echo "フロントエンドとバックエンドを並行起動するには、別々のターミナルで実行してください"
	@echo "  make dev-frontend"
	@echo "  make dev-backend"

dev-frontend:
	cd frontend && npm run dev

dev-backend:
	cd backend && poetry run uvicorn app.main:app --reload --port 8000

# ==============================
# テスト
# ==============================
test: test-frontend test-backend

test-frontend:
	cd frontend && npm test

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
# デプロイ
# ==============================
AWS_REGION ?= ap-northeast-1
ECR_REPO = 412420079063.dkr.ecr.$(AWS_REGION).amazonaws.com/app-prototype-api-dev
LAMBDA_FUNCTION = app-prototype-api-dev
S3_BUCKET = app-prototype-frontend-dev
CLOUDFRONT_ID = E3MKYSY7TC8WOW
API_URL = https://i7yz3ihjzj.execute-api.$(AWS_REGION).amazonaws.com

deploy: deploy-backend deploy-frontend
	@echo "デプロイ完了!"

deploy-backend:
	@echo "=== バックエンドをデプロイ ==="
	aws ecr get-login-password --region $(AWS_REGION) | docker login --username AWS --password-stdin $(ECR_REPO)
	cd backend && docker build -t $(ECR_REPO):latest .
	docker push $(ECR_REPO):latest
	aws lambda update-function-code --function-name $(LAMBDA_FUNCTION) --image-uri $(ECR_REPO):latest --region $(AWS_REGION)
	aws lambda wait function-updated --function-name $(LAMBDA_FUNCTION) --region $(AWS_REGION)
	@echo "バックエンドデプロイ完了!"

deploy-frontend:
	@echo "=== フロントエンドをデプロイ ==="
	cd frontend && VITE_API_URL=$(API_URL) npm run build
	aws s3 sync frontend/dist/ s3://$(S3_BUCKET) --delete --region $(AWS_REGION)
	aws cloudfront create-invalidation --distribution-id $(CLOUDFRONT_ID) --paths "/*" --region $(AWS_REGION)
	@echo "フロントエンドデプロイ完了!"

deploy-infra:
	@echo "=== インフラをデプロイ ==="
	cd infrastructure/terraform && terraform init -upgrade && terraform apply -auto-approve

# ==============================
# ローカル環境 (Docker)
# ==============================
local-up:
	cd local && docker compose up -d

local-down:
	cd local && docker compose down

local-logs:
	cd local && docker compose logs -f

local-build:
	cd local && docker compose build --no-cache

local-clean:
	cd local && docker compose down -v --rmi local

# ==============================
# クリーンアップ
# ==============================
clean:
	rm -rf frontend/dist frontend/build frontend/node_modules/.cache
	rm -rf backend/dist backend/build backend/__pycache__
	find . -type d -name "__pycache__" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".pytest_cache" -exec rm -rf {} + 2>/dev/null || true
	find . -type d -name ".mypy_cache" -exec rm -rf {} + 2>/dev/null || true
