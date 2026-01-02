#!/usr/bin/env python3
"""DynamoDB Local 初期化スクリプト"""
import os
import sys

import boto3
from botocore.exceptions import ClientError

DYNAMODB_ENDPOINT = os.environ.get("DYNAMODB_ENDPOINT_URL", "http://127.0.0.1:8000")
TABLE_NAME = os.environ.get("DYNAMODB_TABLE_NAME", "app-prototype-local")
AWS_REGION = os.environ.get("AWS_DEFAULT_REGION", "ap-northeast-1")


def main() -> int:
    print("=== DynamoDB Local 初期化 ===")

    # ダミー認証情報を設定
    os.environ.setdefault("AWS_ACCESS_KEY_ID", "dummy")
    os.environ.setdefault("AWS_SECRET_ACCESS_KEY", "dummy")

    client = boto3.client(
        "dynamodb",
        endpoint_url=DYNAMODB_ENDPOINT,
        region_name=AWS_REGION,
    )

    try:
        client.describe_table(TableName=TABLE_NAME)
        print(f"テーブル '{TABLE_NAME}' は既に存在します")
    except ClientError as e:
        if e.response["Error"]["Code"] == "ResourceNotFoundException":
            print("テーブルを作成中...")
            client.create_table(
                TableName=TABLE_NAME,
                AttributeDefinitions=[
                    {"AttributeName": "PK", "AttributeType": "S"},
                    {"AttributeName": "SK", "AttributeType": "S"},
                ],
                KeySchema=[
                    {"AttributeName": "PK", "KeyType": "HASH"},
                    {"AttributeName": "SK", "KeyType": "RANGE"},
                ],
                BillingMode="PAY_PER_REQUEST",
            )
            print(f"テーブル '{TABLE_NAME}' を作成しました")
        else:
            print(f"エラー: {e}")
            return 1

    print("")
    print("=== 初期化完了 ===")
    return 0


if __name__ == "__main__":
    sys.exit(main())
