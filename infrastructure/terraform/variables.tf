variable "project_name" {
  description = "プロジェクト名"
  type        = string
  default     = "app-prototype"
}

variable "environment" {
  description = "環境名 (dev, staging, prod)"
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWSリージョン"
  type        = string
  default     = "ap-northeast-1"
}
