"""
它界 TAF — 项目 CRUD 路由
"""
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, and_

from models.database import Project, Facility, gen_uuid
from schemas.models import (
    ProjectCreate, ProjectUpdate, ProjectOut, ProjectListOut,
)
from deps import get_db, get_current_user

router = APIRouter(prefix="/api/projects", tags=["项目"])


def generate_project_code(product_line: str, phase: str, db_session) -> str:
    """生成项目代码: OS-NC-2026-001"""
    from datetime import datetime
    year = datetime.utcnow().year
    # count existing projects of same product_line this year
    return f"{product_line}-{phase}-{year}"  # suffix added on create


@router.post("", response_model=ProjectOut, status_code=201)
async def create_project(data: ProjectCreate, db: AsyncSession = Depends(get_db)):
    # Generate code
    from datetime import datetime
    year = datetime.utcnow().year
    result = await db.execute(
        select(func.count()).select_from(Project).where(
            Project.product_line == data.product_line,
            Project.deleted_at.is_(None)
        )
    )
    count = result.scalar() + 1
    code = f"{data.product_line}-{data.phase}-{year}-{count:03d}"

    project = Project(
        code=code,
        name=data.name,
        description=data.description,
        product_line=data.product_line,
        phase=data.phase,
        standard_id=data.standard_id,
        client_name=data.client_name,
        client_company=data.client_company,
        location=data.location,
        custom_weights=data.custom_weights,
    )
    db.add(project)
    await db.commit()
    await db.refresh(project)
    return project


@router.get("", response_model=ProjectListOut)
async def list_projects(
    page: int = Query(1, ge=1),
    page_size: int = Query(20, ge=1, le=100),
    product_line: str = Query(None),
    status: str = Query(None),
    search: str = Query(None),
    db: AsyncSession = Depends(get_db),
):
    query = select(Project).where(Project.deleted_at.is_(None))

    if product_line:
        query = query.where(Project.product_line == product_line)
    if status:
        query = query.where(Project.status == status)
    if search:
        query = query.where(
            Project.name.ilike(f"%{search}%") | Project.code.ilike(f"%{search}%")
        )

    # Count
    count_q = select(func.count()).select_from(query.subquery())
    total = (await db.execute(count_q)).scalar()

    # Paginate
    query = query.order_by(Project.updated_at.desc()).offset((page - 1) * page_size).limit(page_size)
    result = await db.execute(query)
    projects = result.scalars().all()

    # Enrich with facility count
    items = []
    for p in projects:
        fc = (await db.execute(
            select(func.count()).select_from(Facility).where(Facility.project_id == p.id)
        )).scalar()
        out = ProjectOut.model_validate(p)
        out.facility_count = fc
        items.append(out)

    return ProjectListOut(items=items, total=total, page=page, page_size=page_size)


@router.get("/{project_id}", response_model=ProjectOut)
async def get_project(project_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(404, "项目不存在")
    return project


@router.put("/{project_id}", response_model=ProjectOut)
async def update_project(project_id: UUID, data: ProjectUpdate, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(404, "项目不存在")

    update_data = data.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(project, k, v)

    await db.commit()
    await db.refresh(project)
    return project


@router.delete("/{project_id}", status_code=204)
async def delete_project(project_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    project = result.scalar_one_or_none()
    if not project:
        raise HTTPException(404, "项目不存在")

    from datetime import datetime
    project.deleted_at = datetime.utcnow()
    project.status = "archived"
    await db.commit()


@router.post("/{project_id}/duplicate", response_model=ProjectOut, status_code=201)
async def duplicate_project(project_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )
    src = result.scalar_one_or_none()
    if not src:
        raise HTTPException(404, "项目不存在")

    # New project
    from datetime import datetime
    year = datetime.utcnow().year
    count_r = await db.execute(
        select(func.count()).select_from(Project).where(
            Project.product_line == src.product_line,
            Project.deleted_at.is_(None)
        )
    )
    count = count_r.scalar() + 1
    code = f"{src.product_line}-{src.phase}-{year}-{count:03d}"

    new_p = Project(
        code=code,
        name=f"{src.name} (副本)",
        description=src.description,
        product_line=src.product_line,
        phase=src.phase,
        standard_id=src.standard_id,
        client_name=src.client_name,
        client_company=src.client_company,
        location=src.location,
        custom_weights=src.custom_weights,
    )
    db.add(new_p)
    await db.flush()

    # Copy facilities
    fac_result = await db.execute(
        select(Facility).where(Facility.project_id == src.id)
    )
    for f in fac_result.scalars():
        new_f = Facility(
            project_id=new_p.id,
            standard_item_id=f.standard_item_id,
            name=f.name,
            type=f.type,
            category=f.category,
            status="draft",
            quantity=f.quantity,
            position=f.position,
            spec=f.spec,
            supplier=f.supplier,
        )
        db.add(new_f)

    await db.commit()
    await db.refresh(new_p)
    return new_p
