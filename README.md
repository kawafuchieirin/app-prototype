
## 構成図
<img width="841" height="711" alt="名称未設定ファイル drawio" src="https://github.com/user-attachments/assets/ab922491-a3ec-4dc8-86ff-852ad79b5030" />



# App Prototype

フルスタックWebアプリケーションのプロトタイプ。

## 技術スタック

### Frontend
- React 19 + TypeScript
- Vite
- Vitest (テスト)
- AWS Amplify (認証)

### Backend
- Python 3.14 + FastAPI
- Poetry (依存関係管理)
- Mangum (Lambda対応)
- pytest (テスト)

### Infrastructure (AWS)
- S3 + CloudFront (フロントエンドホスティング)
- API Gateway + Lambda (バックエンドAPI)
- Cognito (認証)
- DynamoDB (データベース)
- Terraform (IaC)

## 前提条件

- Node.js 22+
- Python 3.14+
- Poetry
- Terraform 1.7+
- AWS CLI (設定済み)

## セットアップ

```bash
# 全ての依存関係をインストール
make install

# pre-commitフックをインストール
make pre-commit-install
```

## 開発

```bash
# 開発サーバー起動
make dev-frontend  # フロントエンド (localhost:5173)
make dev-backend   # バックエンド (localhost:8000)

# テスト実行
make test          # 全テスト
make test-frontend
make test-backend

# リント・フォーマット
make lint
make format

# ビルド
make build
```

## インフラストラクチャ

```bash
# Terraform
make tf-init
make tf-plan
make tf-apply
```

## プロジェクト構成

```
app-prototype/
├── frontend/          # React + Vite アプリケーション
│   └── src/
├── backend/           # FastAPI アプリケーション
│   ├── app/
│   │   ├── routers/   # APIルーター
│   │   ├── main.py    # エントリーポイント
│   │   └── config.py  # 設定
│   └── tests/
└── infrastructure/
    └── terraform/     # AWSインフラ定義
```

## CI/CD

- **CI (ci.yml):** プッシュ・PR時にテスト、リント、ビルドを自動実行
- **Deploy (deploy.yml):** mainブランチへのマージで自動デプロイ

### 必要なGitHub Secrets

- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
