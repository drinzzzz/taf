"""
它界 TAF — 评估引擎路由
"""
from uuid import UUID
from datetime import datetime
import json
from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select, func, text, desc

from models.database import Project, Facility, StandardPlugin, Space, Base
from schemas.models import (
    EvaluationResult, ScoreHistory, StandardSwitchRequest, StandardImpactPreview,
)
from services.evaluation import EvaluationEngine
from deps import get_db

import logging
logger = logging.getLogger("taf.evaluation")

router = APIRouter(prefix="/api/projects", tags=["评估"])


def _build_eval_result(project_id, standard, facilities, custom_weights) -> dict:
    engine = EvaluationEngine(standard.config)
    return engine.calculate_score(
        facilities=[{
            "standard_item_id": f.standard_item_id,
            "type": f.type,
            "category": f.category,
            "status": f.status,
            "quantity": f.quantity,
        } for f in facilities],
        custom_weights=custom_weights,
    )


async def _save_score_history(db: AsyncSession, project_id: UUID, standard_code: str,
                               total_score: float, level: str, stars: int):
    """持久化评分历史到 score_history 表"""
    await db.execute(text("""
        INSERT INTO score_history (id, project_id, standard_code, total_score, level, stars, evaluated_at)
        VALUES (gen_random_uuid(), :pid, :code, :score, :level, :stars, :now)
    """), {"pid": str(project_id), "code": standard_code, "score": total_score,
           "level": level, "stars": stars, "now": datetime.utcnow()})
    await db.commit()


@router.post("/{project_id}/evaluate", response_model=EvaluationResult)
async def evaluate_project(project_id: UUID, db: AsyncSession = Depends(get_db)):
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")
    if not p.standard_id:
        raise HTTPException(400, "项目未绑定评估标准")

    standard = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.id == p.standard_id)
    )).scalar_one_or_none()
    if not standard:
        raise HTTPException(400, "绑定标准不存在")

    fac_result = await db.execute(
        select(Facility).where(Facility.project_id == project_id)
    )
    facilities = fac_result.scalars().all()

    result = _build_eval_result(project_id, standard, facilities, p.custom_weights)

    # 持久化评分历史
    try:
        await _save_score_history(db, project_id, standard.code,
                                   result["total_score"], result["level"], result["stars"])
    except Exception:
        logger.debug("评分历史持久化失败（表可能未创建）", exc_info=True)

    return EvaluationResult(
        project_id=project_id,
        standard_code=standard.code,
        standard_name=standard.name,
        **result,
    )


@router.get("/{project_id}/score", response_model=EvaluationResult)
async def get_score(project_id: UUID, db: AsyncSession = Depends(get_db)):
    return await evaluate_project(project_id, db)


@router.get("/{project_id}/score/history", response_model=list[ScoreHistory])
async def get_score_history(project_id: UUID, db: AsyncSession = Depends(get_db)):
    try:
        result = await db.execute(text("""
            SELECT id, project_id, standard_code, total_score, level, stars, evaluated_at
            FROM score_history WHERE project_id = :pid ORDER BY evaluated_at DESC LIMIT 20
        """), {"pid": str(project_id)})
        rows = result.fetchall()
        return [ScoreHistory(
            id=row[0], project_id=row[1], standard_code=row[2],
            total_score=row[3], level=row[4], stars=row[5], evaluated_at=row[6]
        ) for row in rows]
    except Exception:
        logger.debug("评分历史查询失败", exc_info=True)
        return []


@router.get("/{project_id}/standard", response_model=dict)
async def get_project_standard(project_id: UUID, db: AsyncSession = Depends(get_db)):
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    if not p.standard_id:
        return {"standard": None, "message": "项目未绑定评估标准"}

    standard = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.id == p.standard_id)
    )).scalar_one_or_none()

    if not standard:
        return {"standard": None, "message": "标准已删除"}

    # 返回完整标准对象（code/name/version + config），前端需要这些字段
    return {
        "standard": {
            "code": standard.code,
            "name": standard.name,
            "version": standard.version,
            "status": standard.status,
            "config": standard.config,
        }
    }


@router.get("/{project_id}/standard/preview/{new_code}", response_model=StandardImpactPreview)
async def preview_standard_switch(project_id: UUID, new_code: str, db: AsyncSession = Depends(get_db)):
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    new_standard = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.code == new_code)
    )).scalar_one_or_none()
    if not new_standard:
        raise HTTPException(404, "目标标准不存在")

    # 获取当前标准配置用于对比
    old_config = None
    current_code = None
    if p.standard_id:
        current = (await db.execute(
            select(StandardPlugin).where(StandardPlugin.id == p.standard_id)
        )).scalar_one_or_none()
        if current:
            current_code = current.code
            old_config = current.config

    engine = EvaluationEngine(new_standard.config)
    impact = engine.compare_standards(old_config, new_code)

    return StandardImpactPreview(
        current_code=current_code or "none",
        new_code=new_code,
        score_change=None,
        level_change=None,
        new_prerequisites=[p["id"] for p in impact.get("new_prerequisites", [])],
        removed_items=[r["id"] for r in impact.get("removed_items", [])],
    )


@router.post("/{project_id}/standard/switch")
async def switch_standard(project_id: UUID, data: StandardSwitchRequest, db: AsyncSession = Depends(get_db)):
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")

    new_standard = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.code == data.new_standard_code)
    )).scalar_one_or_none()
    if not new_standard:
        raise HTTPException(404, "目标标准不存在")

    old_id = p.standard_id
    p.standard_id = new_standard.id
    
    # Record change log
    try:
        old_code = None
        if old_id:
            old_std = (await db.execute(
                select(StandardPlugin).where(StandardPlugin.id == old_id)
            )).scalar_one_or_none()
            old_code = old_std.code if old_std else None
        
        await db.execute(text("""
            INSERT INTO standard_change_log (id, project_id, from_standard_code, to_standard_code, impact_summary, applied_at)
            VALUES (gen_random_uuid(), :pid, :from_code, :to_code, :impact, :now)
        """), {
            "pid": str(project_id), "from_code": old_code, "to_code": new_standard.code,
            "impact": json.dumps({"action": "switch", "from": old_code, "to": new_standard.code}),
            "now": datetime.utcnow()
        })
    except Exception:
        logger.debug("标准切换日志记录失败", exc_info=True)
    
    await db.commit()

    return {
        "message": "标准切换成功",
        "from_standard_id": str(old_id) if old_id else None,
        "to_standard_id": str(new_standard.id),
        "to_standard_code": new_standard.code,
    }


@router.get("/{project_id}/report")
async def export_report(project_id: UUID, db: AsyncSession = Depends(get_db)):
    """生成评估报告 HTML"""
    p = (await db.execute(
        select(Project).where(Project.id == project_id, Project.deleted_at.is_(None))
    )).scalar_one_or_none()
    if not p:
        raise HTTPException(404, "项目不存在")
    if not p.standard_id:
        raise HTTPException(400, "项目未绑定评估标准")

    standard = (await db.execute(
        select(StandardPlugin).where(StandardPlugin.id == p.standard_id)
    )).scalar_one_or_none()

    fac_result = await db.execute(
        select(Facility).where(Facility.project_id == project_id)
    )
    facilities = fac_result.scalars().all()

    result = _build_eval_result(project_id, standard, facilities, p.custom_weights)

    now = datetime.utcnow().strftime("%Y-%m-%d %H:%M UTC")
    stars_html = "⭐" * result["stars"] + "☆" * (5 - result["stars"])

    cat_rows = ""
    for cs in result["category_scores"]:
        color = "#67c23a" if cs["percentage"] >= 60 else "#e6a23c" if cs["percentage"] >= 30 else "#f56c6c"
        cat_rows += f"""<tr>
            <td style="padding:10px;border-bottom:1px solid #2a2d3a">{cs['category_id']} {cs['category_name']}</td>
            <td style="padding:10px;border-bottom:1px solid #2a2d3a;text-align:right">{cs['score']}/{cs['max_score']}</td>
            <td style="padding:10px;border-bottom:1px solid #2a2d3a;text-align:right;color:{color};font-weight:600">{cs['percentage']}%</td>
        </tr>"""

    item_rows = ""
    for cs in result["category_scores"]:
        item_rows += f'<tr><td colspan="6" style="padding:8px 10px;background:#ffffff05;font-weight:600;font-size:14px">{cs["category_id"]} {cs["category_name"]}</td></tr>'
        for item in cs["items"]:
            status_icon = "✅" if item.get("status") in ("confirmed", "installed") else "⬜" if item.get("has_facility") else "❌"
            label = item.get("achieved_label", "")
            item_rows += f"""<tr>
                <td style="padding:6px 10px;font-family:monospace;font-size:12px;color:#4f8cff">{item['item_id']}</td>
                <td style="padding:6px 10px;font-size:13px">{item['name']}</td>
                <td style="padding:6px 10px;font-size:12px;text-align:center">{item['type']}</td>
                <td style="padding:6px 10px;font-size:12px;text-align:center">{status_icon}</td>
                <td style="padding:6px 10px;font-size:11px;color:#8b8fa3">{label}</td>
                <td style="padding:6px 10px;font-size:12px;text-align:right">{item['score']}/{item['score_max']}</td>
            </tr>"""

    recs_html = "".join(f"<li>{r}</li>" for r in result.get("recommendations", []))

    html = f"""<!DOCTYPE html>
<html lang="zh-CN">
<head><meta charset="UTF-8"><title>TAF 评估报告 — {p.name}</title>
<style>
body{{font-family:-apple-system,sans-serif;background:#0f1117;color:#e4e6eb;max-width:900px;margin:40px auto;padding:0 20px}}
h1{{font-size:24px;margin-bottom:4px}}h2{{font-size:16px;color:#8b8fa3;margin:0 0 24px}}
.card{{background:#1a1d27;border:1px solid #2a2d3a;border-radius:8px;padding:20px;margin-bottom:16px}}
table{{width:100%;border-collapse:collapse}}th{{text-align:left;padding:8px 10px;font-size:11px;color:#8b8fa3;text-transform:uppercase;border-bottom:1px solid #2a2d3a}}
.score{{font-size:48px;font-weight:700;color:#67c23a}}.stars{{font-size:24px;margin:8px 0}}.level{{font-size:20px;font-weight:600}}
.footer{{text-align:center;color:#8b8fa3;font-size:12px;margin-top:40px;padding:20px}}
@media print{{body{{background:#fff;color:#000}}.card{{background:#f9f9f9;border:1px solid #ddd}}}}
</style></head>
<body>
<h1>📊 {p.name}</h1>
<h2>评估报告 · {standard.code} v{standard.version} · {now}</h2>

<div class="card">
  <div class="score">{result['total_score']}<span style="font-size:20px">/100</span></div>
  <div class="stars">{stars_html}</div>
  <div class="level">{result['level']}</div>
  <div style="margin-top:12px;font-size:13px;color:#8b8fa3">
    必选项: {result['prerequisite_passed']}/{result['prerequisite_total']} · 产品线: {p.product_line} · 阶段: {p.phase}
  </div>
</div>

<div class="card"><h3 style="margin:0 0 12px;font-size:14px">📈 各板块得分</h3><table>
<tr><th>板块</th><th style="text-align:right">得分</th><th style="text-align:right">得分率</th></tr>
{cat_rows}</table></div>

<div class="card"><h3 style="margin:0 0 12px;font-size:14px">📋 评估明细</h3><table>
<tr><th>编号</th><th>评估项</th><th style="text-align:center">类型</th><th style="text-align:center">状态</th><th>达成等级</th><th style="text-align:right">得分</th></tr>
{item_rows}</table></div>

<div class="card"><h3 style="margin:0 0 12px;font-size:14px">💡 建议与行动项</h3>
<ol style="margin:0;padding-left:20px">{recs_html}</ol></div>

<div class="footer"><p>它界 TAF — 人宠友好空间评估平台</p>
<p>标准: {standard.name} · 报告生成: {now}</p></div>
</body></html>"""

    return {"report_html": html, "score": result["total_score"], "level": result["level"]}
