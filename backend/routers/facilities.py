"""
它界 TAF — 设施路由
"""
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func

from models.database import Facility, Project, StandardPlugin
from schemas.models import (
    FacilityCreate, FacilityUpdate, FacilityOut, FacilityBatchCreate,
)
from deps import get_db

router = APIRouter(prefix="/api", tags=["设施"])


@router.get("/projects/{project_id}/facilities", response_model=list[FacilityOut])
async def list_facilities(
    project_id: UUID,
    category: str = Query(None),
    type: str = Query(None),
    status: str = Query(None),
    db: AsyncSession = Depends(get_db),
):
    # Verify project exists
    p = (await db.execute(select(Project).where(Project.id == project_id, Project.deleted_at.is_(None)))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    query = select(Facility).where(Facility.project_id == project_id)
    if category:
        query = query.where(Facility.category == category)
    if type:
        query = query.where(Facility.type == type)
    if status:
        query = query.where(Facility.status == status)

    query = query.order_by(Facility.category, Facility.standard_item_id)
    result = await db.execute(query)
    return result.scalars().all()


@router.post("/projects/{project_id}/facilities", response_model=FacilityOut, status_code=201)
async def create_facility(project_id: UUID, data: FacilityCreate, db: AsyncSession = Depends(get_db)):
    p = (await db.execute(select(Project).where(Project.id == project_id, Project.deleted_at.is_(None)))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    facility = Facility(project_id=project_id, **data.model_dump())
    db.add(facility)
    await db.commit()
    await db.refresh(facility)
    return facility


@router.get("/facilities/{facility_id}", response_model=FacilityOut)
async def get_facility(facility_id: UUID, db: AsyncSession = Depends(get_db)):
    f = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalar_one_or_none()
    if not f:
        raise HTTPException(404, "设施不存在")
    return f


@router.put("/facilities/{facility_id}", response_model=FacilityOut)
async def update_facility(facility_id: UUID, data: FacilityUpdate, db: AsyncSession = Depends(get_db)):
    f = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalar_one_or_none()
    if not f:
        raise HTTPException(404, "设施不存在")

    update_data = data.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(f, k, v)

    await db.commit()
    await db.refresh(f)
    return f


@router.delete("/facilities/{facility_id}", status_code=204)
async def delete_facility(facility_id: UUID, db: AsyncSession = Depends(get_db)):
    f = (await db.execute(select(Facility).where(Facility.id == facility_id))).scalar_one_or_none()
    if not f:
        raise HTTPException(404, "设施不存在")
    await db.delete(f)
    await db.commit()


@router.post("/projects/{project_id}/facilities/batch", response_model=list[FacilityOut], status_code=201)
async def batch_create_facilities(project_id: UUID, data: FacilityBatchCreate, db: AsyncSession = Depends(get_db)):
    p = (await db.execute(select(Project).where(Project.id == project_id, Project.deleted_at.is_(None)))).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    facilities = []
    for fc in data.facilities:
        f = Facility(project_id=project_id, **fc.model_dump())
        db.add(f)
        facilities.append(f)

    await db.commit()
    for f in facilities:
        await db.refresh(f)
    return facilities


@router.post("/projects/{project_id}/facilities/auto-place")
async def auto_place_facilities(project_id: UUID, db: AsyncSession = Depends(get_db)):
    """自动布点：基于标准项和空间类型规则生成设施建议"""
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")
    if not p.standard_id:
        raise HTTPException(400, "项目未绑定评估标准")

    from services.evaluation import EvaluationEngine

    standard = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.id == p.standard_id)
    )).scalar_one_or_none()

    fac_result = await db.execute(
        select(Facility).where(Facility.project_id == project_id)
    )
    existing = {f.standard_item_id for f in fac_result.scalars().all()}

    # 动态生成布点规则：从标准 config 的 categories 读取，循环分配网格区域
    cats = standard.config.get("categories", [])
    default_space_types = ["building", "channel", "node", "green", "facade"]
    placement_rules = {}
    for i, cat in enumerate(cats):
        cat_id = cat["id"]
        # 按序号轮换空间类型 + 网格偏移
        st_idx = i % len(default_space_types)
        placement_rules[cat_id] = {
            "space_types": [default_space_types[st_idx], default_space_types[(st_idx + 1) % len(default_space_types)]],
            "grid_x": 50 + (i % 5) * 60,
            "grid_y": 50 + (i // 5) * 120,
            "step": 40 + (i % 3) * 15,
        }
    # 兜底
    if not placement_rules:
        placement_rules = {"P1": {"space_types": ["building", "channel"], "grid_x": 100, "grid_y": 50, "step": 50}}

    suggestions = []
    items = standard.config.get("items", [])

    for item in items:
        if item["id"] in existing:
            continue
        rules = placement_rules.get(item.get("category", "P1"), placement_rules["P1"])
        idx = len(suggestions)
        col = idx % 4
        row = idx // 4
        x = rules["grid_x"] + col * rules["step"]
        y = rules["grid_y"] + row * rules["step"]
        suggestions.append({
            "standard_item_id": item["id"],
            "name": item.get("name", item["id"]),
            "type": item.get("type", "credit"),
            "category": item.get("category", "P1"),
            "suggested_position": {"x": x, "y": y, "lng": None, "lat": None},
            "reason": f"{item['category']} 类设施建议布点在 {', '.join(rules['space_types'])} 空间附近",
        })

    return {
        "total_suggestions": len(suggestions),
        "existing_count": len(existing),
        "suggestions": suggestions,
    }
