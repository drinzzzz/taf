"""
它界 TAF — FastAPI 主入口
"""
import logging
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from sqlalchemy import text

from config import get_settings
from deps import get_engine, get_async_sessionmaker
from models.database import Base

# ── 全局日志配置（业务 logger taf.* 输出到 stderr → journalctl）──
# 2026-09-02: 此前无任何 logging 配置, 业务日志(上传/评估/成果生成)全被静默吞掉,
# 排查问题只能靠 uvicorn 访问日志。此处统一接管, INFO 及以上可见。
logging.basicConfig(
    level=logging.INFO,
    format="%(asctime)s %(levelname)s %(name)s: %(message)s",
)
logging.getLogger("taf").setLevel(logging.INFO)
logging.getLogger("uvicorn.access").setLevel(logging.WARNING)  # 访问日志降噪

from routers.projects import router as projects_router
from routers.facilities import router as facilities_router
from routers.standards import router as standards_router
from routers.evaluation import router as evaluation_router
from routers.basemaps import router as basemaps_router
from routers.deliverables import router as deliverables_router


@asynccontextmanager
async def lifespan(app: FastAPI):
    """启动时创建缺失的表（容错已存在的）"""
    import logging
    logger = logging.getLogger("taf")
    try:
        async with get_engine().begin() as conn:
            await conn.run_sync(Base.metadata.create_all)
        logger.info("Database tables verified")
    except Exception as e:
        logger.warning("create_all skipped (tables may already exist): %s", e)
    yield
    await get_engine().dispose()


settings = get_settings()

app = FastAPI(
    title=settings.app_name,
    version=settings.version,
    docs_url="/docs",
    lifespan=lifespan,
)

# CORS
app.add_middleware(
    CORSMiddleware,
    allow_origins=[o.strip() for o in settings.cors_origins.split(",") if o.strip()],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers

# ── Client config endpoint ──
@app.get("/api/config")
async def client_config():
    return {"api_base_path": settings.api_base_path, "version": settings.version}

app.include_router(projects_router)
app.include_router(facilities_router)
app.include_router(standards_router)
app.include_router(evaluation_router)
app.include_router(basemaps_router)
app.include_router(deliverables_router)


@app.get("/")
async def root():
    return {"app": settings.app_name, "version": settings.version, "status": "running"}


@app.get("/health")
async def health():
    try:
        async with get_async_sessionmaker()() as session:
            await session.execute(text("SELECT 1"))
        db_ok = True
    except Exception:
        db_ok = False
    return {"status": "ok", "db": "connected" if db_ok else "unreachable"}
