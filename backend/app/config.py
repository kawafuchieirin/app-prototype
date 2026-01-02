from pydantic_settings import BaseSettings


class Settings(BaseSettings):
    app_name: str = "App Prototype API"
    app_version: str = "0.1.0"
    debug: bool = False
    allowed_origins: list[str] = ["http://localhost:5173", "http://localhost:3000"]

    # AWS
    aws_region: str = "ap-northeast-1"
    dynamodb_table_name: str = "app-prototype"
    dynamodb_endpoint_url: str | None = None  # ローカル環境用（例: http://localhost:8000）

    class Config:
        env_file = ".env"
        env_file_encoding = "utf-8"


settings = Settings()
