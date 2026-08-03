"""
它界 TAF — 配置模块
"""
from pydantic import field_validator
from pydantic_settings import BaseSettings, SettingsConfigDict
from functools import lru_cache


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", env_file_encoding="utf-8")

    app_name: str = "TAF — 它界人宠友好空间评估平台"
    version: str = "1.0.0"
    debug: bool = False

    # PostgreSQL
    db_host: str = "localhost"
    db_port: int = 5432
    db_user: str = "postgres"
    db_password: str = ""
    db_name: str = "taf"
    db_pool_size: int = 10

    @field_validator("db_password")
    @classmethod
    def password_must_be_set(cls, v: str) -> str:
        if not v or not v.strip():
            raise ValueError("DB_PASSWORD 不能为空，请在 .env 或环境变量中设置")
        return v

    # CORS — 逗号分隔的允许域名
    allowed_origins: str = "http://localhost:8080"

    # API Token — 简易认证（Header: X-API-Token），空则不校验
    api_token: str = ""

    # Redis（预留，当前未使用）
    redis_url: str = "redis://localhost"

    @property
    def database_url(self) -> str:
        from urllib.parse import quote_plus
        pw = quote_plus(self.db_password) if self.db_password else ""
        return f"postgresql+asyncpg://{self.db_user}:{pw}@{self.db_host}:{self.db_port}/{self.db_name}"

    @property
    def database_url_sync(self) -> str:
        from urllib.parse import quote_plus
        pw = quote_plus(self.db_password) if self.db_password else ""
        return f"postgresql+psycopg2://{self.db_user}:{pw}@{self.db_host}:{self.db_port}/{self.db_name}"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
