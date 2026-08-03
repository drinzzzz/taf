"""
它界 TAF — FastAPI 主入口
"""
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware

from config import get_settings
from deps import get_engine, get_async_sessionmaker
from models.database import Base

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
    allow_origins=[o.strip() for o in settings.allowed_origins.split(",") if o.strip()],
    allow_methods=["*"],
    allow_headers=["*"],
)

# Routers
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
            await session.execute(
                __import__("sqlalchemy").text("SELECT 1")
            )
        db_ok = True
    except Exception:
        db_ok = False
    return {"status": "ok", "db": "connected" if db_ok else "unreachable"}
