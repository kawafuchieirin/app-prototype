# Python 3.14 slim イメージをベースに使用
FROM python:3.14-slim AS builder

# Lambda Web Adapter用のビルド依存関係
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    && rm -rf /var/lib/apt/lists/*

# 依存関係をインストール
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt -t /app/deps

# 本番イメージ
FROM python:3.14-slim

# Lambda Runtime Interface Emulator (RIE) と Lambda Web Adapter
COPY --from=public.ecr.aws/awsguru/aws-lambda-adapter:0.8.4 /lambda-adapter /opt/extensions/lambda-adapter

# 依存関係をコピー
COPY --from=builder /app/deps /app/deps
ENV PYTHONPATH=/app/deps

# アプリケーションコードをコピー
WORKDIR /app
COPY app ./app

# Lambda Web Adapter の設定
ENV PORT=8000
ENV AWS_LAMBDA_EXEC_WRAPPER=/opt/extensions/lambda-adapter

# uvicorn でアプリケーションを起動
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
