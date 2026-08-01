"""
它界 TAF — 底图/空间路由
"""
from uuid import UUID
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.database import Project, Basemap, Space
from schemas.models import BasemapOut, SpaceOut, SpaceCreate
from deps import get_db

router = APIRouter(prefix="/api", tags=["底图与空间"])


# ── 底图 ──

@router.get("/projects/{project_id}/basemaps", response_model=list[BasemapOut])
async def list_basemaps(project_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Basemap).where(Basemap.project_id == project_id).order_by(Basemap.created_at.desc())
    )
    return result.scalars().all()


@router.post("/projects/{project_id}/basemaps", response_model=BasemapOut, status_code=201)
async def upload_basemap(
    project_id: UUID,
    name: str = None,
    file: UploadFile = File(...),
    db: AsyncSession = Depends(get_db),
):
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    import os, aiofiles
    upload_dir = f"/root/data/disk/taf_uploads/{project_id}"
    os.makedirs(upload_dir, exist_ok=True)

    file_path = os.path.join(upload_dir, file.filename)
    async with aiofiles.open(file_path, "wb") as f:
        content = await file.read()
        await f.write(content)

    ext = file.filename.rsplit(".", 1)[-1].lower() if "." in file.filename else "unknown"
    basemap = Basemap(
        project_id=project_id,
        name=name or file.filename,
        file_type=ext,
        file_url=file_path,
    )
    db.add(basemap)
    await db.commit()
    await db.refresh(basemap)
    return basemap


@router.delete("/basemaps/{basemap_id}", status_code=204)
async def delete_basemap(basemap_id: UUID, db: AsyncSession = Depends(get_db)):
    bm = (await db.execute(select(Basemap).where(Basemap.id == basemap_id))).scalar_one_or_none()
    if not bm:
        raise HTTPException(404, "底图不存在")

    # Clean up file
    import os
    if bm.file_url and os.path.exists(bm.file_url):
        os.remove(bm.file_url)

    await db.delete(bm)
    await db.commit()


# ── 空间 ──

@router.get("/projects/{project_id}/spaces", response_model=list[SpaceOut])
async def list_spaces(project_id: UUID, db: AsyncSession = Depends(get_db)):
    result = await db.execute(
        select(Space).where(Space.project_id == project_id).order_by(Space.created_at)
    )
    return result.scalars().all()


@router.post("/projects/{project_id}/spaces", response_model=SpaceOut, status_code=201)
async def create_space(project_id: UUID, data: SpaceCreate, db: AsyncSession = Depends(get_db)):
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    space = Space(project_id=project_id, **data.model_dump())
    db.add(space)
    await db.commit()
    await db.refresh(space)
    return space


@router.put("/spaces/{space_id}", response_model=SpaceOut)
async def update_space(space_id: UUID, data: SpaceCreate, db: AsyncSession = Depends(get_db)):
    s = (await db.execute(select(Space).where(Space.id == space_id))).scalar_one_or_none()
    if not s:
        raise HTTPException(404, "空间不存在")

    update_data = data.model_dump(exclude_unset=True)
    for k, v in update_data.items():
        setattr(s, k, v)

    await db.commit()
    await db.refresh(s)
    return s


@router.delete("/spaces/{space_id}", status_code=204)
async def delete_space(space_id: UUID, db: AsyncSession = Depends(get_db)):
    s = (await db.execute(select(Space).where(Space.id == space_id))).scalar_one_or_none()
    if not s:
        raise HTTPException(404, "空间不存在")
    await db.delete(s)
    await db.commit()


@router.post("/projects/{project_id}/spaces/recognize")
async def recognize_spaces(project_id: UUID, db: AsyncSession = Depends(get_db)):
    """DXF空间识别：从项目底图提取空间实体"""
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    # Get latest DXF basemap
    bm_result = await db.execute(
        select(Basemap).where(
            Basemap.project_id == project_id,
            Basemap.file_type == "dxf"
        ).order_by(Basemap.created_at.desc()).limit(1)
    )
    basemap = bm_result.scalar_one_or_none()
    if not basemap:
        raise HTTPException(404, "项目无DXF底图，请先上传")

    # Parse DXF and extract layers as spaces
    import ezdxf
    doc = ezdxf.readfile(str(basemap.file_url))
    msp = doc.modelspace()

    # Layer → space type mapping
    layer_type_map = {
        "TAF-BUILDING": "building", "BUILDING": "building",
        "TAF-CHANNEL": "channel", "CHANNEL": "channel",
        "TAF-NODE": "node", "NODE": "node",
        "TAF-ROAD": "road", "ROAD": "road",
        "TAF-GREEN": "green", "GREEN": "green",
        "TAF-FACADE": "facade", "FACADE": "facade",
    }

    # Count entities per layer
    layer_counts = {}
    for entity in msp:
        layer = entity.dxf.layer
        layer_counts[layer] = layer_counts.get(layer, 0) + 1

    # Create spaces for each recognized layer
    created = []
    for layer_name, count in layer_counts.items():
        space_type = layer_type_map.get(layer_name, "transition")
        space = Space(
            project_id=project_id,
            basemap_id=basemap.id,
            name=f"{layer_name} ({count} entities)",
            type=space_type,
            properties={"layer": layer_name, "entity_count": count, "source": "dxf_recognize"},
        )
        db.add(space)
        created.append(space)

    await db.commit()
    for s in created:
        await db.refresh(s)

    return {
        "recognized": len(created),
        "spaces": [{"id": str(s.id), "name": s.name, "type": s.type,
                     "properties": s.properties} for s in created]
    }
