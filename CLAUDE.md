# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

フルスタックWebアプリケーションのプロトタイプ。

### 技術スタック

**Frontend:**
- React 19 + TypeScript
- Vite
- Vitest (テスト)
- カスタム認証サービス (Cognito API直接呼び出し)

**Backend:**
- Python 3.14 + FastAPI
- Poetry (依存関係管理)
- Mangum (Lambda対応)
- pytest (テスト)

**Infrastructure (AWS):**
- S3 + CloudFront (フロントエンドホスティング)
- API Gateway + Lambda (バックエンドAPI)
- Cognito (認証)
- DynamoDB (データベース)
- Terraform (IaC)

**Local Development:**
- cognito-local (Cognitoエミュレータ)
- DynamoDB Local
- Docker Compose

## Getting Started

### 前提条件

- Node.js 22+
- Python 3.14+
- Poetry
- Docker (ローカル開発用)
- Terraform 1.7+ (tenvで管理)
- AWS CLI (設定済み)

### セットアップ

```bash
# 全ての依存関係をインストール
make install

# pre-commitフックをインストール
make pre-commit-install
```

## Common Commands

```bash
# ヘルプを表示
make help

# ローカル開発（AWS使用）
make dev              # フロントエンド+バックエンドを同時起動
make dev-frontend     # フロントエンドのみ (localhost:5173)
make dev-backend      # バックエンドのみ (localhost:8001)

# ローカル開発（Docker使用 - 認証あり）
make local-init       # 初回のみ: Cognito/DynamoDB Localを初期化
make dev-local        # フロント+バックエンド起動（cognito-local使用）

# テスト実行
make test             # 全テスト
make test-frontend
make test-backend

# リント・フォーマット
make lint
make format

# ビルド
make build

# AWSデプロイ
make deploy           # バックエンド+フロントエンドをデプロイ
make deploy-backend   # バックエンドのみ
make deploy-frontend  # フロントエンドのみ

# Terraform
make tf-init
make tf-plan
make tf-apply
```

## Architecture

```
app-prototype/
├── frontend/                # React + Vite アプリケーション
│   └── src/
│       ├── api/             # APIクライアント
│       ├── components/      # UIコンポーネント
│       ├── contexts/        # React Context (AuthProvider)
│       ├── hooks/           # カスタムフック (useAuth)
│       ├── services/        # 認証サービス
│       └── types/           # 型定義
├── backend/                 # FastAPI アプリケーション
│   ├── app/
│   │   ├── routers/         # APIルーター
│   │   ├── services/        # ビジネスロジック
│   │   ├── models/          # データモデル
│   │   ├── auth.py          # Cognito JWT認証
│   │   ├── main.py          # エントリーポイント
│   │   └── config.py        # 設定
│   └── tests/
├── infrastructure/
│   └── terraform/           # AWSインフラ定義
└── local/                   # ローカル開発環境
    ├── docker-compose.yml   # cognito-local, DynamoDB Local
    └── scripts/             # 初期化スクリプト
```

## 認証アーキテクチャ

ローカル環境とAWS環境で**同一のコード**を使用し、環境変数でエンドポイントを切り替えます。

```
┌─────────────────────────────────────────────────────────┐
│                    同一コードベース                       │
├─────────────────────────────────────────────────────────┤
│  Frontend                  │  Backend                   │
│  ├── services/auth.ts      │  ├── auth.py               │
│  ├── contexts/AuthContext  │  ├── config.py             │
│  └── hooks/useAuth.ts      │  └── routers/todos.py      │
├─────────────────────────────────────────────────────────┤
│         ↓ 環境変数で切り替え ↓                           │
├──────────────────────┬──────────────────────────────────┤
│   ローカル環境        │   AWS環境                        │
│   cognito-local      │   AWS Cognito                    │
│   DynamoDB Local     │   AWS DynamoDB                   │
└──────────────────────┴──────────────────────────────────┘
```

### 環境変数

| 変数名 | ローカル | AWS |
|--------|----------|-----|
| `VITE_COGNITO_ENDPOINT` | `http://127.0.0.1:9229` | (未設定) |
| `VITE_COGNITO_USER_POOL_ID` | cognito-localのID | AWSのPool ID |
| `VITE_COGNITO_CLIENT_ID` | cognito-localのClient ID | AWSのClient ID |
| `COGNITO_ENDPOINT_URL` | `http://127.0.0.1:9229` | (未設定) |
| `DYNAMODB_ENDPOINT_URL` | `http://127.0.0.1:8000` | (未設定) |

### ローカル開発（認証あり）

```bash
# 1. Docker環境を初期化（初回のみ）
make local-init

# 2. 開発サーバー起動
make dev-local

# テストユーザー
# Email: test@example.com
# Password: Test1234!
```

## CI/CD

- **CI (ci.yml):** プッシュ・PR時にテスト、リント、ビルドを自動実行
- **Deploy (deploy.yml):** mainブランチへのマージで自動デプロイ

### 必要なGitHub Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
