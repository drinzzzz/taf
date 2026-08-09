"""
它界 TAF — 评估标准路由
"""
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.database import StandardPlugin
from schemas.models import (
    StandardPluginCreate, StandardPluginOut, StandardPluginBrief,
)
from deps import get_db, get_current_user

router = APIRouter(prefix="/api/standards", tags=["评估标准"])


@router.get("", response_model=list[StandardPluginBrief])
async def list_standards(
    status: str = Query(None),
    db: AsyncSession = Depends(get_db),
):
    query = select(StandardPlugin)
    if status:
        query = query.where(StandardPlugin.status == status)
    query = query.order_by(StandardPlugin.release_date.desc())
    result = await db.execute(query)
    return result.scalars().all()


@router.post("", response_model=StandardPluginOut, status_code=201)
async def create_standard(data: StandardPluginCreate, user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    existing = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.code == data.code)
    )).scalar_one_or_none()
    if existing:
        raise HTTPException(409, f"标准 code '{data.code}' 已存在")

    standard = StandardPlugin(**data.model_dump())
    db.add(standard)
    await db.commit()
    await db.refresh(standard)
    return standard


@router.get("/current", response_model=StandardPluginBrief)
async def get_current_standard(db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(StandardPlugin).where(StandardPlugin.status == "active").order_by(StandardPlugin.release_date.desc()).limit(1)
    )
    standard = result.scalar_one_or_none()
    if not standard:
        raise HTTPException(404, "无活跃标准")
    return standard


@router.get("/{code}", response_model=StandardPluginOut)
async def get_standard(code: str, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(StandardPlugin).where(StandardPlugin.code == code)
    )
    standard = result.scalar_one_or_none()
    if not standard:
        raise HTTPException(404, "标准不存在")
    return standard


@router.put("/{code}", response_model=StandardPluginOut)
async def update_standard(code: str, data: StandardPluginCreate, user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(StandardPlugin).where(StandardPlugin.code == code)
    )
    standard = result.scalar_one_or_none()
    if not standard:
        raise HTTPException(404, "标准不存在")

    # Auto-version: create new version instead of overwriting
    import re
    m = re.match(r"^(.+_v)(\d+)\.(\d+)$", code)
    if m:
        prefix, major, minor = m.group(1), int(m.group(2)), int(m.group(3))
        new_version_code = f"{prefix}{major}.{minor + 1}"
    else:
        new_version_code = f"{code}_v2"

    # Deactivate old version
    standard.status = "superseded"
    await db.flush()

    # Create new version with bumped code
    from datetime import datetime
    new_data = data.model_dump()
    new_data["code"] = new_version_code
    new_data["version"] = f"{major}.{minor + 1}" if m else "2.0"
    new_data["status"] = "active"
    new_data["release_date"] = datetime.utcnow()
    new_standard = StandardPlugin(**new_data)
    db.add(new_standard)
    await db.commit()
    await db.refresh(new_standard)

    await db.commit()
    return new_standard


@router.post("/{code}/activate", response_model=StandardPluginOut)
async def activate_standard(code: str, user: dict = Depends(get_current_user), db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(StandardPlugin).where(StandardPlugin.code == code)
    )
    standard = result.scalar_one_or_none()
    if not standard:
        raise HTTPException(404, "标准不存在")

    standard.status = "active"
    await db.commit()
    await db.refresh(standard)
    return standard
