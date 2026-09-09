"""
它界 TAF — 点位版本历史路由

GET    /api/projects/{pid}/placements/versions              版本列表
GET    /api/projects/{pid}/placements/versions/{vid}        版本详情 (含快照 + 与当前差异)
POST   /api/projects/{pid}/placements/versions              手动存档当前点位
POST   /api/projects/{pid}/placements/versions/{vid}/restore 恢复到该版本
"""
from uuid import UUID

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import PlacementVersion, Project
from schemas.models import PlacementVersionCreate, PlacementVersionDetailOut, PlacementVersionOut
from deps import get_db, get_current_user
from services.placement_history import diff_snapshot, record_version, restore_version, snapshot_project

router = APIRouter(prefix="/api", tags=["点位历史"])


async def _ensure_project(db: AsyncSession, project_id: UUID) -> Project:
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")
    return p


async def _get_version(db: AsyncSession, project_id: UUID, version_id: UUID) -> PlacementVersion:
    v = (await db.execute(
        select(PlacementVersion).where(
            PlacementVersion.id == version_id, PlacementVersion.project_id == project_id)
    )).scalar_one_or_none()
    if not v:
        raise HTTPException(404, "版本不存在")
    return v


@router.get("/projects/{project_id}/placements/versions", response_model=list[PlacementVersionOut])
async def list_placement_versions(
    project_id: UUID,
    limit: int = Query(100, ge=1, le=500),
    db: AsyncSession = Depends(get_db),
):
    """版本列表 (新 → 旧)"""
    await _ensure_project(db, project_id)
    res = await db.execute(
        select(PlacementVersion)
        .where(PlacementVersion.project_id == project_id)
        .order_by(PlacementVersion.version_no.desc())
        .limit(limit)
    )
    return res.scalars().all()


@router.get("/projects/{project_id}/placements/versions/{version_id}",
            response_model=PlacementVersionDetailOut)
async def get_placement_version(project_id: UUID, version_id: UUID, db: AsyncSession = Depends(get_db)):
    """版本详情: 快照 + 与当前点位的差异 (新增/删除/移动)"""
    await _ensure_project(db, project_id)
    v = await _get_version(db, project_id, version_id)
    current = await snapshot_project(db, project_id)
    return PlacementVersionDetailOut(
        id=v.id, project_id=v.project_id, version_no=v.version_no, label=v.label, note=v.note,
        source=v.source, scope=v.scope, point_count=v.point_count, facility_count=v.facility_count,
        created_at=v.created_at, created_by=v.created_by, restored_from=v.restored_from,
        snapshot=v.snapshot or {"placements": []},
        diff=diff_snapshot(v.snapshot or {}, current),
    )


@router.post("/projects/{project_id}/placements/versions",
             response_model=PlacementVersionOut, status_code=201)
async def create_placement_version(
    project_id: UUID,
    body: PlacementVersionCreate,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """手动存档: 把当前点位状态存为一个版本"""
    await _ensure_project(db, project_id)
    v = await record_version(
        db, project_id,
        source="manual",
        label=body.label or "手动存档",
        note=body.note,
        scope="project",
        created_by=user.get("user_id"),
    )
    return v


@router.post("/projects/{project_id}/placements/versions/{version_id}/restore")
async def restore_placement_version(
    project_id: UUID,
    version_id: UUID,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """恢复项目点位到指定版本 (恢复前自动存档当前状态)"""
    await _ensure_project(db, project_id)
    v = await _get_version(db, project_id, version_id)
    result = await restore_version(db, project_id, v, created_by=user.get("user_id"))
    result["restored_from_version"] = v.version_no
    return result
