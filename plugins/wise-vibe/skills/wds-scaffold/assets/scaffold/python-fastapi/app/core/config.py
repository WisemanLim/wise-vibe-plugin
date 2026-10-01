"""{{PROJECT_NAME}} — settings (env 주입: .env.local | .env.prod 는 compose env_file 로 전달)."""
from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(extra="ignore")

    app_name: str = "{{PROJECT_NAME}}"
    app_env: str = "local"
    db_engine: str = "sqlite"
    database_url: str = "sqlite:////app/data/app.db"


settings = Settings()
