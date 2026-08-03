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

    update_data = data.model_dump(exclude={"code"})
    for k, v in update_data.items():
        setattr(standard, k, v)

    await db.commit()
    await db.refresh(standard)
    return standard


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
