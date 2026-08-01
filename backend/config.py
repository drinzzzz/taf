"""
它界 TAF — 配置模块
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    app_name: str = "TAF — 它界人宠友好空间评估平台"
    version: str = "1.0.0"
    debug: bool = False

    # PostgreSQL
    db_host: str = "127.0.0.1"
    db_port: int = 5432
    db_user: str = "postgres"
    db_password: str = ""
    db_name: str = "taf"
    db_pool_size: int = 10

    # Redis
    redis_url: str = "redis://127.0.0.1:6379"

    @property
    def database_url(self) -> str:
        return f"postgresql+asyncpg://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"

    @property
    def database_url_sync(self) -> str:
        return f"postgresql+psycopg2://{self.db_user}:{self.db_password}@{self.db_host}:{self.db_port}/{self.db_name}"


@lru_cache()
def get_settings() -> Settings:
    return Settings()
