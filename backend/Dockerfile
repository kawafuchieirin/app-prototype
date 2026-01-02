FROM public.ecr.aws/lambda/python:3.13

# 依存関係をインストール
COPY requirements.txt ${LAMBDA_TASK_ROOT}/
RUN pip install --no-cache-dir -r requirements.txt

# アプリケーションコードをコピー
COPY app ${LAMBDA_TASK_ROOT}/app

# Lambda ハンドラを指定
CMD ["app.main.handler"]
