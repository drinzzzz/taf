"""
TAF deliverables — 版本管理 + ComfyUI 渲染对接
"""
import os
from uuid import UUID
from datetime import datetime

from fastapi import APIRouter, Depends, HTTPException, Query
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.database import Deliverable
from deps import get_db, get_current_user
from .helpers import _get_project, _get_standard, _get_facilities, logger
from .visualization import _generate_prompts_inline

router = APIRouter(prefix="/api/projects", tags=["策划成果"])


# ═══════════════════════════════════════════
# 版本管理
# ═══════════════════════════════════════════

@router.get("/{project_id}/deliverables/history")
async def get_deliverable_history(
    project_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """获取成果版本历史"""
    result = await db.execute(
        select(Deliverable).where(
            Deliverable.project_id == project_id,
        ).order_by(Deliverable.generated_at.desc())
    )
    items = result.scalars().all()

    return {
        "project_id": str(project_id),
        "total_versions": len(items),
        "versions": [
            {
                "id": str(d.id),
                "version": d.version,
                "phase": d.phase,
                "files": d.files,
                "config_snapshot": d.config_snapshot,
                "generated_at": d.generated_at.isoformat() if d.generated_at else None,
            }
            for d in items
        ],
    }


@router.post("/{project_id}/deliverables/diff")
async def diff_deliverables(
    project_id: UUID,
    v1: int = Query(...),
    v2: int = Query(...),
    db: AsyncSession = Depends(get_db),
):
    """对比两个版本成果差异"""
    r1 = (await db.execute(
        select(Deliverable).where(
            Deliverable.project_id == project_id, Deliverable.version == v1
        ).limit(1)
    )).scalar_one_or_none()

    r2 = (await db.execute(
        select(Deliverable).where(
            Deliverable.project_id == project_id, Deliverable.version == v2
        ).limit(1)
    )).scalar_one_or_none()

    if not r1 or not r2:
        raise HTTPException(404, "版本不存在")

    files1 = {f["name"]: f for f in (r1.files or [])}
    files2 = {f["name"]: f for f in (r2.files or [])}
    all_names = set(files1.keys()) | set(files2.keys())

    changes = []
    for name in sorted(all_names):
        f1 = files1.get(name)
        f2 = files2.get(name)
        if f1 and f2:
            size_diff = f2.get("size", 0) - f1.get("size", 0)
            changes.append({
                "name": name, "change": "modified",
                "size_v1": f1.get("size"), "size_v2": f2.get("size"),
                "size_delta": size_diff,
            })
        elif f1 and not f2:
            changes.append({"name": name, "change": "removed", "size_v1": f1.get("size")})
        else:
            changes.append({"name": name, "change": "added", "size_v2": f2.get("size")})

    return {
        "project_id": str(project_id),
        "v1": v1, "v2": v2,
        "generated_v1": r1.generated_at.isoformat() if r1.generated_at else None,
        "generated_v2": r2.generated_at.isoformat() if r2.generated_at else None,
        "changes": changes,
    }


# ═══════════════════════════════════════════
# ComfyUI 渲染对接
# ═══════════════════════════════════════════

@router.post("/{project_id}/deliverables/render")
async def render_with_comfyui(
    project_id: UUID,
    space_index: int = Query(None),
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """将渲染提示词提交到 ComfyUI（或输出 dry-run）"""
    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    prompts_data = _generate_prompts_inline(project, standard, facilities)

    from collections import defaultdict
    by_space = defaultdict(list)
    for p in prompts_data["prompts"]:
        by_space[p["space"]].append(p)

    spaces_list = list(by_space.keys())

    if space_index is not None and 0 <= space_index < len(spaces_list):
        spaces_list = [spaces_list[space_index]]

    import httpx
    comfy_url = os.environ.get("COMFYUI_URL", "http://127.0.0.1:8188")
    comfy_available = False
    try:
        async with httpx.AsyncClient(timeout=5) as client:
            r = await client.get(f"{comfy_url}/system_stats")
            if r.status_code == 200:
                comfy_available = True
    except Exception:
        logger.warning("ComfyUI 不可达", exc_info=True)

    results = []
    for space_name in spaces_list:
        space_prompts = by_space[space_name]
        for p in space_prompts:
            sd_prompt = p["stable_diffusion"]
            result = {
                "space": space_name,
                "viewpoint": p["viewpoint"],
                "prompt": sd_prompt,
                "midjourney": p["midjourney"],
            }

            if comfy_available:
                try:
                    async with httpx.AsyncClient(timeout=120) as client:
                        workflow = {
                            "3": {"class_type": "KSampler", "inputs": {"seed": -1, "steps": 30, "cfg": 7, "sampler_name": "euler", "scheduler": "normal", "denoise": 1, "model": ["4", 0], "positive": ["6", 0], "negative": ["7", 0], "latent_image": ["5", 0]}},
                            "4": {"class_type": "CheckpointLoaderSimple", "inputs": {"ckpt_name": "sd_xl_base_1.0.safetensors"}},
                            "5": {"class_type": "EmptyLatentImage", "inputs": {"width": 1024, "height": 576, "batch_size": 1}},
                            "6": {"class_type": "CLIPTextEncode", "inputs": {"text": sd_prompt, "clip": ["4", 1]}},
                            "7": {"class_type": "CLIPTextEncode", "inputs": {"text": "ugly, blurry, low quality", "clip": ["4", 1]}},
                            "8": {"class_type": "VAEDecode", "inputs": {"samples": ["3", 0], "vae": ["4", 2]}},
                            "9": {"class_type": "SaveImage", "inputs": {"filename_prefix": f"TAF_{project.code}", "images": ["8", 0]}},
                        }
                        resp = await client.post(f"{comfy_url}/prompt", json={"prompt": workflow})
                        result["comfyui"] = {"status": resp.status_code, "prompt_id": resp.json().get("prompt_id")}
                except Exception as e:
                    logger.warning("ComfyUI 渲染失败: %s", e)
                    result["comfyui"] = {"status": "error", "error": str(e)}
            else:
                result["comfyui"] = {"status": "dry_run", "note": "ComfyUI 未运行，安装后可自动提交"}

            results.append(result)

    return {
        "project": project.name, "code": project.code,
        "comfyui_available": comfy_available, "comfyui_url": comfy_url,
        "total_renders": len(results),
        "results": results,
    }
