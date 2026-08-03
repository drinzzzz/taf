"""
TAF deliverables — 方案书 + 成果打包器
"""
import os, io, json, tempfile, zipfile
from uuid import UUID
from datetime import datetime

from fastapi import APIRouter, Depends, Query, HTTPException
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.database import Project, Facility, StandardPlugin, Basemap, Space, Deliverable
from services.evaluation import EvaluationEngine
from deps import get_db, get_current_user
from .helpers import _get_project, _get_standard, _get_facilities, _get_all_standards, logger
from .reports import _build_boq_workbook, _build_priority_matrix_core, _build_priority_xlsx

router = APIRouter(prefix="/api/projects", tags=["策划成果"])


# ═══════════════════════════════════════════
# T4: 策划设计方案书
# ═══════════════════════════════════════════

async def _build_proposal_md(project, standard, facilities, db) -> str:
    """共享核心：构建方案书 Markdown 内容。端点和打包器共用。"""
    from jinja2 import Environment, FileSystemLoader

    engine = EvaluationEngine(standard.config)
    evaluation = engine.calculate_score(
        facilities=[{
            "standard_item_id": f.standard_item_id,
            "type": f.type, "category": f.category,
            "status": f.status, "quantity": f.quantity,
        } for f in facilities],
    )

    categories = []
    for c in standard.config.get("categories", []):
        item_count = len([i for i in standard.config.get("items", []) if i["category"] == c["id"]])
        categories.append({"id": c["id"], "name": c["name"], "weight": c["weight"], "item_count": item_count})

    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}
    facilities_by_category = {}
    for f in facilities:
        cat = f.category or "??"
        spec = f.spec or {}
        spec_text = " / ".join(spec.get("brands", [])) or (
            ", ".join(f"{k}:{v}" for k, v in list(spec.items())[:2]) if spec else ""
        )
        facilities_by_category.setdefault(cat, []).append({
            "standard_item_id": f.standard_item_id, "name": f.name,
            "type": f.type, "quantity": f.quantity, "spec_text": spec_text, "status": f.status,
        })

    pm = _build_priority_matrix_core(standard, facilities)
    priority = {"summary": pm["summary"], "items": pm["rows"]}

    all_standards = await _get_all_standards(db)
    benchmark_results = [{
        "code": standard.code, "name": standard.name,
        "total_score": evaluation["total_score"], "level": evaluation["level"],
        "stars": evaluation["stars"], "is_current": True,
    }]
    facility_item_ids = {f.standard_item_id for f in facilities}
    gap_lists = {}
    for s in all_standards:
        if s.code == standard.code or s.status != "active":
            continue
        te = EvaluationEngine(s.config)
        tr = te.calculate_score(facilities=[{
            "standard_item_id": f.standard_item_id, "type": f.type,
            "category": f.category, "status": f.status, "quantity": f.quantity,
        } for f in facilities])
        benchmark_results.append({
            "code": s.code, "name": s.name, "total_score": tr["total_score"],
            "level": tr["level"], "stars": tr["stars"], "is_current": False,
        })
        titems = {i["id"]: i for i in s.config.get("items", [])}
        gaps = []
        for iid, item in titems.items():
            if iid not in facility_item_ids and not item.get("is_optional_facility"):
                gaps.append({"item_id": iid, "name": item["name"],
                             "type": item.get("type", ""), "category": item.get("category", "")})
        if gaps:
            gap_lists[s.code] = gaps
    benchmark = {"results": benchmark_results, "gap_lists": gap_lists}

    env = Environment(loader=FileSystemLoader("/root/TAF/backend/templates"))
    template = env.get_template("proposal.md.j2")
    return template.render(
        project=project, standard=standard, date=datetime.now().strftime("%Y-%m-%d"),
        evaluation=evaluation, categories=categories, facilities=facilities,
        facilities_by_category=facilities_by_category, cat_names=cat_names,
        priority=priority, benchmark=benchmark,
    )


@router.post("/{project_id}/deliverables/proposal")
async def generate_proposal(
    project_id: UUID,
    format: str = Query("md", regex="^(md|pdf)$"),
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """生成策划设计方案书"""
    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    md_content = await _build_proposal_md(project, standard, facilities, db)

    if format == "md":
        from urllib.parse import quote
        filename = f"{project.code}_策划设计方案书.md"
        return StreamingResponse(
            io.BytesIO(md_content.encode("utf-8")),
            media_type="text/markdown; charset=utf-8",
            headers={"Content-Disposition": f"attachment; filename*=UTF-8''{quote(filename)}"},
        )

    import markdown as md_lib
    from weasyprint import HTML as WeasyHTML

    html_body = md_lib.markdown(md_content, extensions=['tables', 'fenced_code'])
    html = f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<style>body{{font-family:'Noto Sans CJK SC',sans-serif;max-width:900px;margin:40px auto;padding:0 20px;color:#333;line-height:1.8}}
h1{{font-size:24px;border-bottom:2px solid #2F5496;padding-bottom:8px}}
h2{{font-size:18px;color:#2F5496;margin-top:32px}}
h3{{font-size:15px}}
table{{width:100%;border-collapse:collapse;margin:16px 0;font-size:12px}}
th{{background:#2F5496;color:white;padding:6px 8px;text-align:left}}
td{{padding:6px 8px;border-bottom:1px solid #ddd}}
tr:nth-child(even){{background:#f5f7fa}}
@media print{{body{{font-size:11px}}}}</style></head>
<body>{html_body}</body></html>"""

    pdf_bytes = io.BytesIO()
    WeasyHTML(string=html).write_pdf(pdf_bytes)
    pdf_bytes.seek(0)

    from urllib.parse import quote
    filename = f"{project.code}_策划设计方案书.pdf"
    return StreamingResponse(
        pdf_bytes,
        media_type="application/pdf",
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{quote(filename)}"},
    )


# ═══════════════════════════════════════════
# T5: 成果打包器
# ═══════════════════════════════════════════

@router.post("/{project_id}/deliverables/package")
async def generate_package(
    project_id: UUID,
    upload: bool = Query(True),
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """一键生成所有策划成果，打包 ZIP 并上传坚果云"""
    import markdown as md_lib
    from weasyprint import HTML as WeasyHTML

    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    # Phase 2 依赖：获取底图和空间
    bm_result = await db.execute(
        select(Basemap).where(
            Basemap.project_id == project_id, Basemap.file_type == "dxf"
        ).order_by(Basemap.created_at.desc()).limit(1)
    )
    basemap_global = bm_result.scalar_one_or_none()
    space_result = await db.execute(select(Space).where(Space.project_id == project_id))
    spaces_global = list(space_result.scalars().all())

    manifest = []
    tmp_dir = tempfile.mkdtemp(prefix="taf_deliverables_")
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    pkg_dir = os.path.join(tmp_dir, f"{project.code}_{timestamp}")
    os.makedirs(pkg_dir, exist_ok=True)

    try:
        # ── 1. 设施清单 XLSX ──
        boq_path = os.path.join(pkg_dir, f"{project.code}_设施配置清单.xlsx")
        wb = _build_boq_workbook(project, standard, facilities)
        wb.save(boq_path)
        manifest.append({"name": "设施配置清单.xlsx", "path": boq_path, "format": "xlsx"})

        # ── 2. 优先级矩阵 XLSX ──
        priority_path = os.path.join(pkg_dir, f"{project.code}_改造优先级矩阵.xlsx")
        pm = _build_priority_matrix_core(standard, facilities)
        pr_rows = pm["rows"]
        output = _build_priority_xlsx(project.name, pr_rows)
        with open(priority_path, "wb") as f:
            f.write(output.getvalue())
        manifest.append({"name": "改造优先级矩阵.xlsx", "path": priority_path, "format": "xlsx"})

        # ── 3. 方案书 PDF ──
        md_content = await _build_proposal_md(project, standard, facilities, db)
        html_body = md_lib.markdown(md_content, extensions=['tables', 'fenced_code'])
        html = f"""<!DOCTYPE html><html><head><meta charset="utf-8">
<style>body{{font-family:'Noto Sans CJK SC',sans-serif;max-width:900px;margin:40px auto;padding:0 20px;color:#333;line-height:1.8}}
h1{{font-size:24px;border-bottom:2px solid #2F5496;padding-bottom:8px}}
h2{{font-size:18px;color:#2F5496;margin-top:32px}}h3{{font-size:15px}}
table{{width:100%;border-collapse:collapse;margin:16px 0;font-size:12px}}
th{{background:#2F5496;color:white;padding:6px 8px;text-align:left}}
td{{padding:6px 8px;border-bottom:1px solid #ddd}}
tr:nth-child(even){{background:#f5f7fa}}
@media print{{body{{font-size:11px}}}}</style></head>
<body>{html_body}</body></html>"""
        proposal_path = os.path.join(pkg_dir, f"{project.code}_策划设计方案书.pdf")
        WeasyHTML(string=html).write_pdf(proposal_path)
        manifest.append({"name": "策划设计方案书.pdf", "path": proposal_path, "format": "pdf"})

        # ── 4. 布点图 DXF ──
        from .layout import _generate_layout_dxf_inline
        layout_path = os.path.join(pkg_dir, f"{project.code}_设施布点图.dxf")
        _generate_layout_dxf_inline(project, standard, facilities, spaces_global, basemap_global, layout_path)
        manifest.append({"name": "设施布点图.dxf", "path": layout_path, "format": "dxf"})

        # ── 5-7. 标注图 + 叙事 + 提示词 ──
        from .visualization import _generate_annotated_map_inline, _generate_narrative_inline, _generate_prompts_inline

        annotated_path = os.path.join(pkg_dir, f"{project.code}_标注渲染图.png")
        _generate_annotated_map_inline(project, standard, facilities, None, annotated_path)
        manifest.append({"name": "标注渲染图.png", "path": annotated_path, "format": "png"})

        narrative_path = os.path.join(pkg_dir, f"{project.code}_空间叙事.md")
        narrative_md = _generate_narrative_inline(project, standard, facilities)
        with open(narrative_path, "w", encoding="utf-8") as nf:
            nf.write(narrative_md)
        manifest.append({"name": "空间叙事.md", "path": narrative_path, "format": "md"})

        prompts_path = os.path.join(pkg_dir, f"{project.code}_AI渲染提示词.json")
        prompts_data = _generate_prompts_inline(project, standard, facilities)
        with open(prompts_path, "w", encoding="utf-8") as pf:
            json.dump(prompts_data, pf, ensure_ascii=False, indent=2)
        manifest.append({"name": "AI渲染提示词.json", "path": prompts_path, "format": "json"})

        # ── 产物清单 ──
        manifest_md = f"# 成果包清单\n\n项目: {project.name} ({project.code})\n生成时间: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}\n\n"
        for i, m in enumerate(manifest, 1):
            size = os.path.getsize(m["path"])
            manifest_md += f"{i}. **{m['name']}** ({m['format'].upper()}, {size:,} bytes)\n"
        manifest_path = os.path.join(pkg_dir, "成果清单.md")
        with open(manifest_path, "w", encoding="utf-8") as f:
            f.write(manifest_md)
        manifest.append({"name": "成果清单.md", "path": manifest_path, "format": "md"})

        # ── 打包 ZIP ──
        zip_path = os.path.join(tmp_dir, f"{project.code}_{timestamp}_成果包.zip")
        with zipfile.ZipFile(zip_path, "w", zipfile.ZIP_DEFLATED) as zf:
            for m in manifest:
                zf.write(m["path"], os.path.basename(m["path"]))
        zip_size = os.path.getsize(zip_path)

        # ── 上传坚果云 ──
        nutstore_result = None
        if upload:
            nutstore_user = "drin@vip.qq.com"
            nutstore_pass = os.environ.get("NUTSTORE_PASSWORD", "")
            if not nutstore_pass:
                logger.warning("坚果云上传跳过：未设置 NUTSTORE_PASSWORD 环境变量")
                nutstore_result = {"status": "skipped", "reason": "NUTSTORE_PASSWORD 未配置"}
            else:
                from urllib.parse import quote
                import subprocess
                zip_filename = f"{project.code}_{timestamp}_成果包.zip"
                remote_path = f"01_CURR_PRJ/{quote(project.name)}/{quote('成果包')}/{quote('NC')}"
                dirs_to_create = [
                    f"01_CURR_PRJ/{quote(project.name)}",
                    f"01_CURR_PRJ/{quote(project.name)}/{quote('成果包')}",
                    f"01_CURR_PRJ/{quote(project.name)}/{quote('成果包')}/{quote('NC')}",
                ]
                for dir_path in dirs_to_create:
                    subprocess.run([
                        "curl", "-s", "-u", f"{nutstore_user}:{nutstore_pass}",
                        "-X", "MKCOL", f"https://dav.jianguoyun.com/dav/{dir_path}",
                        "--connect-timeout", "5", "--max-time", "10",
                    ], capture_output=True)
                result = subprocess.run([
                    "curl", "-s", "-u", f"{nutstore_user}:{nutstore_pass}",
                    "-T", zip_path,
                    f"https://dav.jianguoyun.com/dav/{remote_path}/{quote(zip_filename)}",
                    "-w", "%{http_code}",
                    "--connect-timeout", "5", "--max-time", "30",
                ], capture_output=True, text=True)
                http_code = result.stdout.strip()
                nutstore_result = {
                    "status": int(http_code) if http_code.isdigit() else "error",
                    "path": f"01_CURR_PRJ/{project.name}/成果包/NC/{zip_filename}",
                }
                if result.returncode != 0:
                    nutstore_result["error"] = result.stderr[:200]

        # ── 收集文件信息后清理临时文件 ──
        file_info = []
        for m in manifest:
            size = os.path.getsize(m["path"]) if os.path.exists(m["path"]) else 0
            file_info.append({"name": m["name"], "format": m["format"], "size": size})

        import shutil
        shutil.rmtree(tmp_dir, ignore_errors=True)

        # ── 保存版本快照 ──
        last_ver = (await db.execute(
            select(Deliverable.version).where(
                Deliverable.project_id == project_id,
                Deliverable.phase == project.phase,
            ).order_by(Deliverable.version.desc()).limit(1)
        )).scalar()
        new_version = (last_ver or 0) + 1

        snapshot = Deliverable(
            project_id=project_id, phase=project.phase, version=new_version,
            files=file_info,
            config_snapshot={
                "standard_code": standard.code, "standard_name": standard.name,
                "facility_count": len(facilities),
            },
        )
        db.add(snapshot)
        await db.commit()

        return {
            "project": project.name, "code": project.code,
            "timestamp": timestamp, "version": new_version,
            "files": file_info, "zip_size": zip_size, "nutstore": nutstore_result,
        }

    except Exception as e:
        import shutil
        logger.exception("成果打包失败")
        shutil.rmtree(tmp_dir, ignore_errors=True)
        raise HTTPException(500, f"打包失败: {e}")
