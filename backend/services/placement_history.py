"""
它界 TAF — 点位版本历史服务

职责: 项目全量点位快照的生成 / 记录 / 恢复。
设计要点:
  · 版本 = 项目全部点位的一份完整快照 → 任何变更(含删除)都能原样还原
  · 快照在变更提交之后生成(读的是变更后的真实状态)
  · 单点高频操作(拖拽/加点)按 scope + 时间窗合并, 避免版本爆炸
  · 恢复前自动存档当前状态, 恢复动作本身也留痕
"""
from __future__ import annotations

import logging
from datetime import datetime, timedelta
from typing import Optional
from uuid import UUID

from sqlalchemy import delete, select
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import Facility, FacilityPlacement, PlacementVersion

logger = logging.getLogger("taf.placement_history")

# 单点自动变更的合并窗口(秒): 同一设施在此窗口内的连续拖拽/加点合并为一条版本
AUTO_COALESCE_SECONDS = 900


async def snapshot_project(db: AsyncSession, project_id) -> dict:
    """读取项目当前全部点位 → 快照 dict"""
    res = await db.execute(
        select(FacilityPlacement, Facility.standard_item_id, Facility.name)
        .join(Facility, Facility.id == FacilityPlacement.facility_id)
        .where(FacilityPlacement.project_id == project_id)
        .order_by(Facility.standard_item_id, FacilityPlacement.seq)
    )
    rows = []
    for pl, item_id, fname in res.all():
        pos = pl.position or {}
        rows.append({
            "placement_id": str(pl.id),
            "facility_id": str(pl.facility_id),
            "standard_item_id": item_id,
            "name": fname,
            "seq": pl.seq,
            "position": dict(pos),
        })
    return {"placements": rows}


def _counts(snap: dict) -> tuple[int, int]:
    rows = snap.get("placements", []) if isinstance(snap, dict) else []
    return len(rows), len({r.get("facility_id") for r in rows})


async def record_version(
    db: AsyncSession,
    project_id,
    *,
    source: str,
    label: Optional[str] = None,
    note: Optional[str] = None,
    created_by: Optional[str] = None,
    scope: Optional[str] = None,
    coalesce_seconds: int = 0,
    restored_from=None,
    snapshot: Optional[dict] = None,
) -> PlacementVersion:
    """记录一条版本快照(默认取当前 DB 状态)"""
    snap = snapshot if snapshot is not None else await snapshot_project(db, project_id)
    points, facs = _counts(snap)

    last = (await db.execute(
        select(PlacementVersion)
        .where(PlacementVersion.project_id == project_id)
        .order_by(PlacementVersion.version_no.desc())
        .limit(1)
    )).scalar_one_or_none()

    if (
        coalesce_seconds
        and last is not None
        and last.source == source
        and (last.scope or "") == (scope or "")
        and last.created_at
        and (datetime.utcnow() - last.created_at) <= timedelta(seconds=coalesce_seconds)
    ):
        last.label = label
        last.note = note
        last.snapshot = snap
        last.point_count = points
        last.facility_count = facs
        await db.commit()
        await db.refresh(last)
        return last

    row = PlacementVersion(
        project_id=project_id,
        version_no=(last.version_no + 1) if last else 1,
        label=label,
        note=note,
        source=source,
        scope=scope,
        snapshot=snap,
        point_count=points,
        facility_count=facs,
        created_by=created_by,
        restored_from=restored_from,
    )
    db.add(row)
    await db.commit()
    await db.refresh(row)
    logger.info("placement version recorded: project=%s v%s source=%s points=%s",
                project_id, row.version_no, source, points)
    return row


async def restore_version(
    db: AsyncSession, project_id, version: PlacementVersion, *, created_by: Optional[str] = None
) -> dict:
    """把项目点位还原到某版本快照 (恢复前先自动存档当前状态)"""
    snap = version.snapshot or {}
    rows = snap.get("placements", []) or []

    # 1) 恢复前存档
    await record_version(
        db, project_id,
        source="pre_restore",
        label=f"恢复前自动存档 (目标 v{version.version_no})",
        scope="project",
    )

    # 2) 校验设施归属, 已被删除的设施跳过并报告
    fac_rows = (await db.execute(
        select(Facility.id).where(Facility.project_id == project_id)
    )).all()
    alive = {str(r[0]) for r in fac_rows}

    # 3) 清空项目全部点位 → 按快照重建
    await db.execute(delete(FacilityPlacement).where(FacilityPlacement.project_id == project_id))
    created, skipped = 0, []
    for r in rows:
        fid = str(r.get("facility_id") or "")
        if fid not in alive:
            skipped.append(r.get("standard_item_id") or fid)
            continue
        db.add(FacilityPlacement(
            facility_id=UUID(fid),
            project_id=project_id,
            seq=int(r.get("seq") or 1),
            position=r.get("position") or {},
        ))
        created += 1
    await db.commit()

    # 4) 恢复动作留痕
    new_ver = await record_version(
        db, project_id,
        source="restore",
        label=f"恢复到 v{version.version_no}" + (f" — {version.label}" if version.label else ""),
        note=f"来源版本 v{version.version_no}",
        scope="project",
        restored_from=version.id,
        created_by=created_by,
    )
    return {
        "restored_points": created,
        "skipped_facilities": sorted(set(skipped)),
        "new_version_no": new_ver.version_no,
    }


def diff_snapshot(snap: dict, current: dict) -> dict:
    """快照 vs 当前 的差异 (键 = 标准项 + 序号)"""
    def index(d):
        out = {}
        for r in (d.get("placements", []) or []):
            out[(r.get("standard_item_id"), int(r.get("seq") or 0))] = r
        return out

    old, cur = index(snap), index(current)
    added, removed, moved, same = [], [], [], 0
    for k in sorted(set(cur) - set(old), key=lambda x: (str(x[0]), x[1])):
        added.append({"key": f"{k[0]}-{k[1]:02d}", "position": cur[k].get("position")})
    for k in sorted(set(old) - set(cur), key=lambda x: (str(x[0]), x[1])):
        removed.append({"key": f"{k[0]}-{k[1]:02d}", "position": old[k].get("position")})
    for k in sorted(set(old) & set(cur), key=lambda x: (str(x[0]), x[1])):
        po, pc = old[k].get("position") or {}, cur[k].get("position") or {}
        dx = abs((po.get("x") or 0) - (pc.get("x") or 0))
        dy = abs((po.get("y") or 0) - (pc.get("y") or 0))
        if dx > 0.5 or dy > 0.5:
            moved.append({
                "key": f"{k[0]}-{k[1]:02d}",
                "from": {"x": po.get("x"), "y": po.get("y")},
                "to": {"x": pc.get("x"), "y": pc.get("y")},
                "delta": {"dx": round((pc.get("x") or 0) - (po.get("x") or 0), 2),
                          "dy": round((pc.get("y") or 0) - (po.get("y") or 0), 2)},
            })
        else:
            same += 1
    return {
        "added": added, "removed": removed, "moved": moved,
        "unchanged": same,
        "summary": {
            "snapshot_points": len(old), "current_points": len(cur),
            "added": len(added), "removed": len(removed), "moved": len(moved), "unchanged": same,
        },
    }
