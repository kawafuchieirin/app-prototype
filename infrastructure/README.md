# Infrastructure

AWSインフラストラクチャをTerraformで管理します。

## アーキテクチャ

```
┌─────────────────────────────────────────────────────────────────┐
│                            AWS                                   │
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │  CloudFront  │────▶│      S3      │     │   Cognito    │    │
│  │              │     │  (Frontend)  │     │ (User Pool)  │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                                                                  │
│  ┌──────────────┐     ┌──────────────┐     ┌──────────────┐    │
│  │ API Gateway  │────▶│    Lambda    │────▶│   DynamoDB   │    │
│  │   (HTTP)     │     │  (FastAPI)   │     │              │    │
│  └──────────────┘     └──────────────┘     └──────────────┘    │
│                                                                  │
└─────────────────────────────────────────────────────────────────┘
```

## 前提条件

- Terraform >= 1.7.0
- AWS CLI (認証設定済み)
- 適切なIAM権限

## ディレクトリ構成

```
infrastructure/
└── terraform/
    ├── versions.tf      # Terraformとプロバイダーのバージョン
    ├── variables.tf     # 入力変数
    ├── outputs.tf       # 出力値
    ├── s3.tf            # S3バケット (フロントエンド)
    ├── cloudfront.tf    # CloudFrontディストリビューション
    ├── lambda.tf        # Lambda関数とIAMロール
    ├── api_gateway.tf   # API Gateway (HTTP API)
    ├── cognito.tf       # Cognito User Pool
    └── dynamodb.tf      # DynamoDBテーブル
```

## 使い方

### 初期化

```bash
cd infrastructure/terraform
terraform init
```

### プラン確認

```bash
terraform plan -var="environment=dev"
```

### 適用

```bash
terraform apply -var="environment=dev"
```

### 破棄

```bash
terraform destroy -var="environment=dev"
```

## 変数

| 変数名 | 説明 | デフォルト値 |
|--------|------|--------------|
| `project_name` | プロジェクト名 | `app-prototype` |
| `environment` | 環境名 (dev, staging, prod) | `dev` |
| `aws_region` | AWSリージョン | `ap-northeast-1` |

### 環境ごとの設定例

```bash
# 開発環境
terraform apply -var="environment=dev"

# ステージング環境
terraform apply -var="environment=staging"

# 本番環境
terraform apply -var="environment=prod"
```

## 出力値

| 出力名 | 説明 |
|--------|------|
| `frontend_bucket_name` | フロントエンド用S3バケット名 |
| `cloudfront_distribution_id` | CloudFrontディストリビューションID |
| `cloudfront_domain_name` | CloudFrontドメイン名 |
| `api_gateway_url` | API Gateway URL |
| `cognito_user_pool_id` | Cognito User Pool ID |
| `cognito_user_pool_client_id` | Cognito User Pool Client ID |
| `dynamodb_table_name` | DynamoDBテーブル名 |

## リモートステート (本番環境)

本番環境ではS3バックエンドを有効化してください。`versions.tf`のコメントを解除し、適切なバケット名を設定します。

```hcl
backend "s3" {
  bucket         = "your-terraform-state-bucket"
  key            = "app-prototype/terraform.tfstate"
  region         = "ap-northeast-1"
  encrypt        = true
  dynamodb_table = "terraform-state-lock"
}
```

## 注意事項

- CloudFront用のACM証明書は`us-east-1`リージョンに作成されます
- Lambda関数のコードは初回デプロイ時はダミーコードが使用され、CI/CDで実際のコードに置き換えられます
- S3バケットはパブリックアクセスがブロックされており、CloudFrontからのみアクセス可能です
