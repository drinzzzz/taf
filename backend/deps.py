"""
它界 TAF — 依赖注入 (DB session, auth)
"""
from typing import AsyncGenerator
from fastapi import Header, HTTPException, status
from sqlalchemy.ext.asyncio import create_async_engine, AsyncSession, async_sessionmaker

from config import get_settings

settings = get_settings()

_engine = None
_async_sessionmaker = None


def get_engine():
    """引擎工厂函数 — 延迟创建，便于测试替换"""
    global _engine
    if _engine is None:
        _engine = create_async_engine(
            settings.database_url,
            pool_size=settings.db_pool_size,
            echo=settings.debug,
        )
    return _engine


def get_async_sessionmaker():
    global _async_sessionmaker
    if _async_sessionmaker is None:
        _async_sessionmaker = async_sessionmaker(
            get_engine(), class_=AsyncSession, expire_on_commit=False
        )
    return _async_sessionmaker


async def get_db() -> AsyncGenerator[AsyncSession, None]:
    async with get_async_sessionmaker()() as session:
        try:
            yield session
        finally:
            await session.close()


async def get_current_user(x_api_token: str = Header(default="")) -> dict:
    """API Token 认证：Header X-API-Token 匹配 settings.api_token。
    如果 api_token 未配置（空字符串），则跳过认证（开发/内网模式）。
    """
    if not settings.api_token:
        # 未配置 token：允许所有请求
        return {"user_id": "authenticated", "role": "admin"}
    if x_api_token != settings.api_token:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="无效的 API Token",
        )
    return {"user_id": "authenticated", "role": "admin"}
