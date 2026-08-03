"""
TAF deliverables — 标注渲染图 + 热力图 + 叙事引擎 + AI 提示词
"""
import os, io, json
from uuid import UUID
from datetime import datetime

from fastapi import APIRouter, Depends, Query
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession

from models.database import Project, Facility, StandardPlugin
from services.evaluation import EvaluationEngine
from deps import get_db
from .helpers import _get_project, _get_standard, _get_facilities, logger

router = APIRouter(prefix="/api/projects", tags=["策划成果"])


# ═══════════════════════════════════════════
# 标注渲染图 PNG
# ═══════════════════════════════════════════

def _build_annotated_map_core(project, standard, facilities, evaluation=None) -> bytes:
    """共享核心：生成标注渲染图 PNG，返回 bytes。"""
    from PIL import Image, ImageDraw

    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}

    W, H = 2000, 1400
    img = Image.new("RGB", (W, H), "#0f1117")
    draw = ImageDraw.Draw(img)

    cat_colors = {
        "P1": "#4FC3F7", "P2": "#81C784", "P3": "#FFB74D",
        "P4": "#E57373", "P5": "#BA68C8", "P6": "#FFD54F",
    }

    zones = {
        "入口广场": (100, 200, 400, 600),
        "主通道": (420, 100, 1580, 400),
        "商业界面": (420, 420, 900, 750),
        "绿地休憩区": (920, 420, 1580, 750),
        "节点广场": (420, 770, 900, 1100),
        "立面展示区": (920, 770, 1580, 1100),
        "离场通道": (100, 1120, 1580, 1300),
    }
    zone_labels = {
        "入口广场": "🚗 入口抵达区", "主通道": "🚶 人宠主动线",
        "商业界面": "🏪 宠物友好商户", "绿地休憩区": "🌿 宠物活动绿地",
        "节点广场": "📍 社交节点广场", "立面展示区": "🏛️ 历史立面展示",
        "离场通道": "👋 离场清洁区",
    }

    for name, (x1, y1, x2, y2) in zones.items():
        draw.rectangle([x1, y1, x2, y2], outline="#2a2d3a", width=2, fill="#1a1d27")
        draw.text((x1 + 10, y1 + 8), zone_labels.get(name, name), fill="#8b8fa3")

    flow_path = [
        (250, 400), (500, 250), (800, 250), (1200, 250), (1500, 250),
        (1500, 550), (1200, 550), (800, 550), (500, 550),
        (500, 900), (800, 900), (1200, 900),
        (500, 1250), (1500, 1250),
    ]
    for i in range(len(flow_path) - 1):
        x1, y1 = flow_path[i]
        x2, y2 = flow_path[i+1]
        draw.line([x1, y1, x2, y2], fill="#4FC3F7", width=3)
        dx, dy = x2 - x1, y2 - y1
        length = (dx**2 + dy**2) ** 0.5
        if length > 0:
            ux, uy = dx/length*8, dy/length*8
            draw.polygon([
                (x2, y2),
                (x2 - ux + uy*0.5, y2 - uy - ux*0.5),
                (x2 - ux - uy*0.5, y2 - uy + ux*0.5),
            ], fill="#4FC3F7")

    cat_counters = {}
    for f in facilities:
        cat = f.category or "P1"
        cat_counters.setdefault(cat, 0)
        idx = cat_counters[cat]
        cat_counters[cat] += 1

        zone_map = {
            "P1": ["入口广场", "主通道"], "P2": ["商业界面", "立面展示区"],
            "P3": ["节点广场"], "P4": ["绿地休憩区", "主通道"],
            "P5": ["节点广场", "主通道"], "P6": ["商业界面", "立面展示区"],
        }
        zones_for_cat = zone_map.get(cat, ["主通道"])
        zone_name = zones_for_cat[idx % len(zones_for_cat)]
        zx1, zy1, zx2, zy2 = zones[zone_name]
        col = idx % 4
        row = idx // 4
        spacing_x = (zx2 - zx1 - 40) // 4
        spacing_y = min(40, (zy2 - zy1 - 40) // max(1, (cat_counters[cat] // 4) + 1))
        x = zx1 + 20 + col * spacing_x + (idx * 7) % 20
        y = zy1 + 30 + row * max(spacing_y, 30)
        color = cat_colors.get(cat, "#FFFFFF")
        r = 6 if f.status in ("confirmed", "installed") else 4
        draw.ellipse([x-r, y-r, x+r, y+r], fill=color, outline="#FFFFFF", width=1)

    legend_x, legend_y = 1630, 50
    draw.text((legend_x, legend_y), "设施图例", fill="#FFFFFF")
    for i, (cat, name) in enumerate(cat_names.items()):
        y = legend_y + 24 + i * 28
        color = cat_colors.get(cat, "#FFF")
        draw.ellipse([legend_x, y, legend_x+12, y+12], fill=color)
        draw.text((legend_x + 18, y), f"{cat} {name}", fill="#8b8fa3")
        count = len([f for f in facilities if f.category == cat])
        draw.text((legend_x + 200, y), f"×{count}", fill="#FFFFFF")

    if evaluation is None:
        engine = EvaluationEngine(standard.config)
        evaluation = engine.calculate_score(facilities=[{
            "standard_item_id": f.standard_item_id, "type": f.type,
            "category": f.category, "status": f.status, "quantity": f.quantity,
        } for f in facilities])

    card_x, card_y = 100, 60
    if evaluation["total_score"] >= 80:
        score_color = "#67c23a"
    elif evaluation["total_score"] >= 60:
        score_color = "#e6a23c"
    else:
        score_color = "#f56c6c"
    draw.rectangle([card_x-5, card_y-5, card_x+455, card_y+85], fill="#1a1d27", outline="#2a2d3a")
    draw.text((card_x, card_y), f"⭐{evaluation['stars']} {evaluation['level']}", fill=score_color)
    draw.text((card_x, card_y+22), f"总分 {evaluation['total_score']}/100 · {project.code}", fill="#8b8fa3")
    draw.text((card_x, card_y+44), f"设施 {len(facilities)}项 · 必选项 {evaluation['prerequisite_passed']}/{evaluation['prerequisite_total']}", fill="#8b8fa3")

    bar_x = card_x
    for i, cat_score in enumerate(evaluation.get("category_scores", [])):
        cat_id = cat_score["category_id"]
        pct = cat_score["score"] / cat_score["max_score"] if cat_score["max_score"] > 0 else 0
        bar_color = cat_colors.get(cat_id, "#FFF")
        bar_w = int(pct * 100)
        by = card_y + 62 + i * 6
        draw.rectangle([bar_x, by, bar_x + bar_w, by + 4], fill=bar_color)
        draw.rectangle([bar_x + bar_w, by, bar_x + 100, by + 4], outline="#2a2d3a")
        draw.text((bar_x + 105, by - 2), f"{cat_id} {pct*100:.0f}%", fill="#8b8fa3")

    output = io.BytesIO()
    img.save(output, format="PNG")
    output.seek(0)
    return output.getvalue()


def _generate_annotated_map_inline(project, standard, facilities, evaluation, output_path):
    """内联版：打包器调用，生成 PNG 保存到指定路径"""
    png_data = _build_annotated_map_core(project, standard, facilities, evaluation)
    with open(output_path, "wb") as f:
        f.write(png_data)


@router.post("/{project_id}/deliverables/annotated-map")
async def generate_annotated_map(
    project_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """生成设施标注渲染图 PNG（评分色块 + 动线箭头 + 设施图标）"""
    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    png_data = _build_annotated_map_core(project, standard, facilities)

    output = io.BytesIO(png_data)
    output.seek(0)

    from urllib.parse import quote
    filename = f"{project.code}_标注渲染图.png"
    return StreamingResponse(
        output,
        media_type="image/png",
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{quote(filename)}"},
    )


# ═══════════════════════════════════════════
# 热力图
# ═══════════════════════════════════════════

@router.get("/{project_id}/deliverables/heatmap")
async def generate_heatmap(
    project_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """生成设施密度热力图 + 服务半径分析 PNG"""
    import matplotlib
    matplotlib.use("Agg")
    import matplotlib.pyplot as plt
    import numpy as np
    from scipy.stats import gaussian_kde

    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}
    cat_colors = {
        "P1": "#4FC3F7", "P2": "#81C784", "P3": "#FFB74D",
        "P4": "#E57373", "P5": "#BA68C8", "P6": "#FFD54F",
    }

    zones = {
        "入口广场": (100, 200, 400, 600, "#1a2a3a"),
        "主通道": (420, 100, 1580, 400, "#1a2a1a"),
        "商业界面": (420, 420, 900, 750, "#1a1a2a"),
        "绿地休憩区": (920, 420, 1580, 750, "#1a2a1a"),
        "节点广场": (420, 770, 900, 1100, "#2a1a1a"),
        "立面展示区": (920, 770, 1580, 1100, "#1a1a2a"),
        "离场通道": (100, 1120, 1580, 1300, "#1a1a1a"),
    }
    zone_map = {
        "P1": ["入口广场", "主通道"], "P2": ["商业界面", "立面展示区"],
        "P3": ["节点广场"], "P4": ["绿地休憩区", "主通道"],
        "P5": ["节点广场", "主通道"], "P6": ["商业界面", "立面展示区"],
    }

    facility_points = []
    cat_counters = {}
    for f in facilities:
        cat = f.category or "P1"
        cat_counters.setdefault(cat, 0)
        idx = cat_counters[cat]
        cat_counters[cat] += 1
        zones_for_cat = zone_map.get(cat, ["主通道"])
        zone_name = zones_for_cat[idx % len(zones_for_cat)]
        zx1, zy1, zx2, zy2, _ = zones[zone_name]
        col = idx % 4
        row = idx // 4
        spacing_x = (zx2 - zx1 - 40) // 4
        spacing_y = min(40, (zy2 - zy1 - 40) // max(1, (cat_counters[cat] // 4) + 1))
        x = zx1 + 20 + col * spacing_x + (idx * 7) % 20
        y = zy1 + 30 + row * max(spacing_y, 30)
        facility_points.append((x, y, cat))

    W, H = 2000, 1400

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(20, 7))
    fig.patch.set_facecolor("#0f1117")

    points = np.array([(p[0], p[1]) for p in facility_points])

    ax1.set_facecolor("#0f1117")
    for name, (zx1, zy1, zx2, zy2, bg) in zones.items():
        ax1.add_patch(plt.Rectangle((zx1, zy1), zx2-zx1, zy2-zy1,
                                     facecolor=bg, edgecolor="#2a2d3a", linewidth=0.5))
        ax1.text((zx1+zx2)/2, zy1-10, name, color="#8b8fa3", fontsize=6, ha="center")

    if len(points) >= 3:
        try:
            kde = gaussian_kde(points.T)
            xi, yi = np.mgrid[0:W:20j, 0:H:14j]
            zi = kde(np.vstack([xi.ravel(), yi.ravel()])).reshape(xi.shape)
            ax1.contourf(xi, yi, zi, levels=12, cmap="YlOrRd", alpha=0.7)
        except Exception:
            logger.exception("KDE 密度估计失败（非致命）")

    for x, y, cat in facility_points:
        color = cat_colors.get(cat, "#FFF")
        ax1.scatter(x, y, c=color, s=15, edgecolors="white", linewidth=0.3, zorder=5)

    ax1.set_xlim(0, W)
    ax1.set_ylim(H, 0)
    ax1.set_title("设施密度热力图", color="#FFFFFF", fontsize=11, pad=8)
    ax1.set_xticks([]); ax1.set_yticks([])

    ax2.set_facecolor("#0f1117")
    for name, (zx1, zy1, zx2, zy2, bg) in zones.items():
        ax2.add_patch(plt.Rectangle((zx1, zy1), zx2-zx1, zy2-zy1,
                                     facecolor=bg, edgecolor="#2a2d3a", linewidth=0.5))

    for x, y, cat in facility_points:
        color = cat_colors.get(cat, "#FFF")
        ax2.add_patch(plt.Circle((x, y), 40, facecolor=color, alpha=0.15,
                                  edgecolor=color, linewidth=0.5))
    for x, y, cat in facility_points:
        color = cat_colors.get(cat, "#FFF")
        ax2.scatter(x, y, c=color, s=20, edgecolors="white", linewidth=0.5, zorder=5)

    ax2.set_xlim(0, W); ax2.set_ylim(H, 0)
    ax2.set_title("服务半径覆盖分析", color="#FFFFFF", fontsize=11, pad=8)
    ax2.set_xticks([]); ax2.set_yticks([])

    legend_handles = []
    for cat in sorted(cat_names.keys()):
        legend_handles.append(plt.Line2D([0], [0], marker="o", color="w",
                                          markerfacecolor=cat_colors.get(cat, "#FFF"),
                                          markersize=8, label=f"{cat} {cat_names[cat]}"))
    fig.legend(handles=legend_handles, loc="lower center", ncol=6,
               facecolor="#0f1117", edgecolor="#2a2d3a", labelcolor="#8b8fa3",
               fontsize=8, framealpha=0.9)

    fig.suptitle(f"{project.name} — 热力图分析 ({project.code})",
                 color="#FFFFFF", fontsize=13, y=0.98)
    plt.tight_layout(rect=[0, 0.06, 1, 0.94])

    output = io.BytesIO()
    fig.savefig(output, format="PNG", dpi=100, facecolor="#0f1117", bbox_inches="tight")
    plt.close(fig)
    output.seek(0)

    from urllib.parse import quote
    filename = f"{project.code}_热力图分析.png"
    return StreamingResponse(
        output,
        media_type="image/png",
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{quote(filename)}"},
    )


# ═══════════════════════════════════════════
# 空间叙事引擎
# ═══════════════════════════════════════════

@router.get("/{project_id}/deliverables/narrative")
async def generate_narrative(
    project_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """生成'携宠游客的一天'空间叙事脚本"""
    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}
    fac_by_cat = {}
    for f in facilities:
        fac_by_cat.setdefault(f.category or "??", []).append(f)

    facility_summary = ""
    for cat, facs in sorted(fac_by_cat.items()):
        facility_summary += f"\n## {cat_names.get(cat, cat)}\n"
        for f in facs:
            spec = f.spec or {}
            spec_str = ", ".join(f"{k}:{v}" for k, v in list(spec.items())[:2]) if spec else ""
            facility_summary += f"- {f.name}（{f.type}, 数量:{f.quantity}, {spec_str}）\n"

    prompt = f"""你是一位建筑叙事设计师。请为"{project.name}"项目撰写一段"携宠游客的一天"空间体验叙事。

项目背景：开放式宠物友好街区，已配置{len(facilities)}项宠物友好设施，获得它界TAF评估100分满分⭐5。

设施清单：
{facility_summary}

要求：
1. 以第一人称"我"叙述，带宠物（狗/猫）游览街区的一天
2. 分为6个场景：🅐抵达 → 🅑漫步 → 🅒休憩 → 🅓社交 → 🅔探索 → 🅕离场
3. 每个场景引用至少2个实际设施，用【设施名称】标注
4. 语气温暖、专业，适合放入策划方案书
5. 每个场景100-150字，总字数600-900字
6. 每个场景标出对应板块编号（P1-P6）
7. 结尾附一段50字总结"""

    try:
        import openai
        api_key = os.environ.get("DEEPSEEK_API_KEY", "")
        if not api_key:
            logger.warning("DeepSeek API key 未配置，使用模板 fallback")
            raise ValueError("DEEPSEEK_API_KEY not set")
        client = openai.OpenAI(base_url="https://api.deepseek.com/v1", api_key=api_key)
        resp = client.chat.completions.create(
            model="deepseek-chat",
            messages=[{"role": "user", "content": prompt}],
            temperature=0.8, max_tokens=2000,
        )
        narrative = resp.choices[0].message.content
    except Exception:
        logger.exception("DeepSeek 叙事生成失败，降级到模板")
        narrative = _generate_narrative_inline(project, standard, facilities)

    return {
        "project": project.name, "code": project.code,
        "narrative": narrative.strip(),
        "facility_count": len(facilities),
    }


def _generate_narrative_inline(project, standard, facilities) -> str:
    """内联版：数据驱动叙事 — 动态引用项目实际设施名称"""
    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}
    fac_by_cat = {}
    for f in facilities:
        fac_by_cat.setdefault(f.category or "??", []).append(f)

    def pick(cat, n=3):
        facs = [f.name for f in fac_by_cat.get(cat, [])]
        return facs[:n] if facs else ["宠物友好设施"]

    p1 = pick("P1"); p2 = pick("P2"); p3 = pick("P3")
    p4 = pick("P4"); p5 = pick("P5"); p6 = pick("P6")

    narrative = f"""# 携宠游客的一天 — {project.name}

## 🅐 抵达（{cat_names.get('P1', 'P1')}）

我驱车驶入{project.name}，入口处的【{p1[0]}】清晰指引着宠物友好停车区。停好车，将牵引绳扣在【{p1[1] if len(p1)>1 else p1[0]}】上，脚下的【{p1[2] if len(p1)>2 else p1[0]}】让毛孩子兴奋地小跑也不会打滑。

## 🅑 漫步（{cat_names.get('P2', 'P2')}）

沿主通道漫步，每走几步就能看到【{p2[0]}】和【{p2[1] if len(p2)>1 else p2[0]}】，让街区始终保持清爽。路过的咖啡馆门口挂着【{p2[2] if len(p2)>2 else p2[0]}】，店员热情地端出宠物专用饮水碗。

## 🅒 休憩（{cat_names.get('P4', 'P4')}）

拐进宠物活动草坪区，毛孩子松开牵引绳在【{p4[0]}】上奔跑打滚。我坐在【{p4[1] if len(p4)>1 else p4[0]}】上，旁边就是饮水点和遮阳设施。草坪边的【{p4[2] if len(p4)>2 else p4[0]}】让精力旺盛的狗狗尽情释放。

## 🅓 社交（{cat_names.get('P5', 'P5')}）

在社交角遇到了同来遛狗的邻居，【{p5[0]}】成了交流养宠心得的好地方。小朋友们在【{p5[1] if len(p5)>1 else p5[0]}】前认真阅读文明养宠守则，社区定期在这里举办【{p5[2] if len(p5)>2 else p5[0]}】。

## 🅔 探索（{cat_names.get('P6', 'P6')}）

沿【{p6[0]}】探访街区历史建筑，每一栋老房子都做了【{p6[1] if len(p6)>1 else p6[0]}】——门框下嵌着猫洞、窗台加装了防护格栅。建筑旁的【{p6[2] if len(p6)>2 else p6[0]}】讲述着街区的人宠共生故事。

## 🅕 离场（{cat_names.get('P3', 'P3')}）

日落时分，在【{p3[0]}】为毛孩子擦脚、梳理毛发。离场通道设有【{p3[1] if len(p3)>1 else p3[0]}】，扫码查看周边最近的宠物医院。出口处记下几家下次要探的店——这里不是宠物友好，这里就是宠物的家。

---

*{project.name} · 人宠共生典范街区 · {len(facilities)}项设施 · 100分满分*
"""
    return narrative.strip()


# ═══════════════════════════════════════════
# AI 渲染提示词管线
# ═══════════════════════════════════════════

@router.get("/{project_id}/deliverables/prompts")
async def generate_rendering_prompts(
    project_id: UUID,
    db: AsyncSession = Depends(get_db),
):
    """为每个空间类型生成 AI 效果图提示词"""
    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}
    fac_by_cat = {}
    for f in facilities:
        fac_by_cat.setdefault(f.category or "??", []).append(f.name)

    space_prompts = [
        {"space": "入口广场", "scene_type": "arrival_plaza", "facility_cats": ["P1"],
         "viewpoints": ["鸟瞰入口全景", "人视角度抵达体验", "宠物视角低位观察"],
         "style": "现代中式开放式街区入口，傍晚暖光，人宠友好氛围"},
        {"space": "主通道", "scene_type": "main_promenade", "facility_cats": ["P1", "P4"],
         "viewpoints": ["通道纵深透视", "人宠并行漫步", "街道断面展示"],
         "style": "宽阔步行通道，两侧宠物友好设施串联，自然光透过树冠"},
        {"space": "商业界面", "scene_type": "commercial_facade", "facility_cats": ["P2", "P6"],
         "viewpoints": ["沿街立面展示", "咖啡馆户外座位区", "商户宠物友好细节"],
         "style": "历史建筑立面与现代商业融合，暖色灯光，户外座椅区宠物社交"},
        {"space": "绿地休憩区", "scene_type": "pet_green_space", "facility_cats": ["P4"],
         "viewpoints": ["草坪全景", "训练设施特写", "人与宠物互动中景"],
         "style": "自然园林风格，开阔草坪，宠物训练设施点缀其间，午后阳光"},
        {"space": "节点广场", "scene_type": "social_node", "facility_cats": ["P3", "P5"],
         "viewpoints": ["广场社交全景", "科普墙互动", "宠物行为培训活动"],
         "style": "社区广场，人宠聚会场景，温暖社区氛围，互动装置"},
        {"space": "立面展示区", "scene_type": "heritage_facade", "facility_cats": ["P6"],
         "viewpoints": ["历史建筑立面", "猫洞/防护格栅细节", "标识系统"],
         "style": "历史建筑立面，精心嵌入宠物友好元素，保留建筑原始韵味"},
        {"space": "离场通道", "scene_type": "departure_zone", "facility_cats": ["P3"],
         "viewpoints": ["清洁站使用场景", "离场通道夜景", "宠物道别瞬间"],
         "style": "整洁离场通道，宠物清洁站温馨灯光，傍晚道别氛围"},
    ]

    prompts = []
    for sp in space_prompts:
        space_facs = []
        for cat in sp["facility_cats"]:
            space_facs.extend(fac_by_cat.get(cat, []))
        fac_list = ", ".join(space_facs[:6]) if space_facs else "宠物友好设施"
        for vp in sp["viewpoints"]:
            prompts.append({
                "space": sp["space"], "scene_type": sp["scene_type"],
                "viewpoint": vp, "facilities": space_facs[:6],
                "midjourney": f"pet-friendly open-block {sp['scene_type']}, {sp['style']}, featuring {fac_list}, {vp}, people with dogs and cats, warm atmosphere, modern Chinese architectural style, architectural visualization, Unreal Engine 5 render, 8K, photorealistic --ar 16:9 --style raw",
                "stable_diffusion": f"masterpiece, best quality, photorealistic, pet-friendly {sp['scene_type']}, {sp['style']}, featuring {fac_list}, {vp}, modern Chinese architecture, warm lighting, afternoon sunlight, people walking dogs, cats, architectural photography, 8K, highly detailed",
            })
    return {
        "project": project.name, "code": project.code,
        "total_prompts": len(prompts), "spaces": len(space_prompts),
        "prompts": prompts,
    }


def _generate_prompts_inline(project, standard, facilities) -> dict:
    """内联版：打包器调用，返回提示词 dict"""
    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}
    fac_by_cat = {}
    for f in facilities:
        fac_by_cat.setdefault(f.category or "??", []).append(f.name)

    space_prompts = [
        {"space": "入口广场", "scene_type": "arrival_plaza", "facility_cats": ["P1"],
         "viewpoints": ["鸟瞰入口全景", "人视角度抵达体验", "宠物视角低位观察"],
         "style": "现代中式开放式街区入口，傍晚暖光，人宠友好氛围"},
        {"space": "主通道", "scene_type": "main_promenade", "facility_cats": ["P1", "P4"],
         "viewpoints": ["通道纵深透视", "人宠并行漫步", "街道断面展示"],
         "style": "宽阔步行通道，两侧宠物友好设施串联，自然光透过树冠"},
        {"space": "商业界面", "scene_type": "commercial_facade", "facility_cats": ["P2", "P6"],
         "viewpoints": ["沿街立面展示", "咖啡馆户外座位区", "商户宠物友好细节"],
         "style": "历史建筑立面与现代商业融合，暖色灯光，户外座椅区宠物社交"},
        {"space": "绿地休憩区", "scene_type": "pet_green_space", "facility_cats": ["P4"],
         "viewpoints": ["草坪全景", "训练设施特写", "人与宠物互动中景"],
         "style": "自然园林风格，开阔草坪，宠物训练设施点缀其间，午后阳光"},
        {"space": "节点广场", "scene_type": "social_node", "facility_cats": ["P3", "P5"],
         "viewpoints": ["广场社交全景", "科普墙互动", "宠物行为培训活动"],
         "style": "社区广场，人宠聚会场景，温暖社区氛围，互动装置"},
        {"space": "立面展示区", "scene_type": "heritage_facade", "facility_cats": ["P6"],
         "viewpoints": ["历史建筑立面", "猫洞/防护格栅细节", "标识系统"],
         "style": "历史建筑立面，精心嵌入宠物友好元素，保留建筑原始韵味"},
        {"space": "离场通道", "scene_type": "departure_zone", "facility_cats": ["P3"],
         "viewpoints": ["清洁站使用场景", "离场通道夜景", "宠物道别瞬间"],
         "style": "整洁离场通道，宠物清洁站温馨灯光，傍晚道别氛围"},
    ]

    prompts = []
    for sp in space_prompts:
        space_facs = []
        for cat in sp["facility_cats"]:
            space_facs.extend(fac_by_cat.get(cat, []))
        fac_list = ", ".join(space_facs[:6]) if space_facs else "宠物友好设施"
        for vp in sp["viewpoints"]:
            prompts.append({
                "space": sp["space"], "scene_type": sp["scene_type"],
                "viewpoint": vp, "facilities": space_facs[:6],
                "midjourney": f"pet-friendly open-block {sp['scene_type']}, {sp['style']}, featuring {fac_list}, {vp}, people with dogs and cats, warm atmosphere, modern Chinese architectural style, architectural visualization, Unreal Engine 5 render, 8K, photorealistic --ar 16:9 --style raw",
                "stable_diffusion": f"masterpiece, best quality, photorealistic, pet-friendly {sp['scene_type']}, {sp['style']}, featuring {fac_list}, {vp}, modern Chinese architecture, warm lighting, afternoon sunlight, people walking dogs, cats, architectural photography, 8K, highly detailed",
            })
    return {
        "project": project.name, "code": project.code,
        "total_prompts": len(prompts), "spaces": len(space_prompts),
        "prompts": prompts,
    }
