"""
TAF deliverables — 共享辅助函数
"""
import logging
from uuid import UUID
from fastapi import HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select
from sqlalchemy.orm import selectinload

from models.database import Project, Facility, StandardPlugin, FacilityPlacement

logger = logging.getLogger("taf.deliverables")


async def _get_project(project_id: UUID, db: AsyncSession) -> Project:
    """拉取项目，404 如果不存在"""
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")
    return p


async def _get_standard(project: Project, db: AsyncSession) -> StandardPlugin:
    """获取项目绑定的标准"""
    if not project.standard_id:
        raise HTTPException(400, "项目未绑定评估标准")
    std = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.id == project.standard_id)
    )).scalar_one_or_none()
    if not std:
        raise HTTPException(400, "绑定标准不存在")
    return std


async def _get_facilities(project_id: UUID, db: AsyncSession) -> list:
    """获取项目设施列表 (含 placements 多实例), 按 category + standard_item_id 排序"""
    result = await db.execute(
        select(Facility)
        .options(selectinload(Facility.placements))
        .where(Facility.project_id == project_id)
        .order_by(Facility.category, Facility.standard_item_id)
    )
    return list(result.scalars().all())


async def _get_all_standards(db: AsyncSession) -> list:
    """获取所有 active 标准"""
    result = await db.execute(
        select(StandardPlugin).where(StandardPlugin.status == "active")
    )
    return list(result.scalars().all())
