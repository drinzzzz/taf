"""
TAF deliverables — DXF 布点图
"""
import os, io, math, tempfile
from uuid import UUID

from fastapi import APIRouter, Depends
from fastapi.responses import StreamingResponse
from sqlalchemy.ext.asyncio import AsyncSession
from sqlalchemy import select

from models.database import Basemap, Space
from deps import get_db, get_current_user
from .helpers import _get_project, _get_standard, _get_facilities
import logging
logger = logging.getLogger("taf.layout")

router = APIRouter(prefix="/api/projects", tags=["策划成果"])


def _build_layout_dxf_core(project, standard, facilities, spaces, basemap) -> bytes:
    """共享核心：生成布点图 DXF，返回 bytes。端点和打包器共用。"""
    import ezdxf
    from ezdxf import colors

    cat_names = {c["id"]: c["name"] for c in standard.config.get("categories", [])}

    if basemap and basemap.file_url and os.path.exists(str(basemap.file_url)):
        doc = ezdxf.readfile(str(basemap.file_url))
    else:
        doc = ezdxf.new("R2010")
        msp = doc.modelspace()
        for name, color in [("TAF-BUILDING", 1), ("TAF-CHANNEL", 3), ("TAF-NODE", 4),
                             ("TAF-ROAD", 5), ("TAF-GREEN", 2), ("TAF-FACADE", 6)]:
            doc.layers.add(name=name, color=color)

    msp = doc.modelspace()

    layer_bboxes = {}
    for entity in msp:
        lt = entity.dxftype()
        layer = entity.dxf.layer
        if lt == 'LINE':
            xs = [entity.dxf.start.x, entity.dxf.end.x]
            ys = [entity.dxf.start.y, entity.dxf.end.y]
        elif lt == 'LWPOLYLINE':
            pts = entity.get_points()
            if pts:
                xs = [p[0] for p in pts]
                ys = [p[1] for p in pts]
            else:
                continue
        elif lt == 'CIRCLE':
            cx, cy, r = entity.dxf.center.x, entity.dxf.center.y, entity.dxf.radius
            xs = [cx - r, cx + r]
            ys = [cy - r, cy + r]
        else:
            continue
        if layer not in layer_bboxes:
            layer_bboxes[layer] = [min(xs), min(ys), max(xs), max(ys)]
        else:
            b = layer_bboxes[layer]
            layer_bboxes[layer] = [min(b[0], min(xs)), min(b[1], min(ys)),
                                   max(b[2], max(xs)), max(b[3], max(ys))]

    type_to_layer = {
        "building": "TAF-BUILDING", "channel": "TAF-CHANNEL",
        "node": "TAF-NODE", "road": "TAF-ROAD",
        "green": "TAF-GREEN", "facade": "TAF-FACADE",
    }
    space_centers = {}
    for s in spaces:
        layer = type_to_layer.get(s.type, "TAF-BUILDING")
        bbox = layer_bboxes.get(layer)
        if bbox:
            space_centers[layer] = ((bbox[0] + bbox[2]) / 2, (bbox[1] + bbox[3]) / 2)

    if not space_centers:
        fallback = {"TAF-BUILDING": (300, 200), "TAF-CHANNEL": (500, 120),
                    "TAF-NODE": (650, 250), "TAF-ROAD": (400, 300),
                    "TAF-GREEN": (200, 360), "TAF-FACADE": (550, 180)}
        for s in spaces:
            layer = type_to_layer.get(s.type, "TAF-BUILDING")
            space_centers[layer] = fallback.get(layer, (400, 250))

    if "TAF-FACILITY" not in doc.layers:
        doc.layers.add(name="TAF-FACILITY", color=colors.RED)
    if "TAF-LABEL" not in doc.layers:
        doc.layers.add(name="TAF-LABEL", color=colors.CYAN)
    if "TAF-LEGEND" not in doc.layers:
        doc.layers.add(name="TAF-LEGEND", color=colors.WHITE)

    cat_colors = {"P1": 1, "P2": 2, "P3": 3, "P4": 4, "P5": 5, "P6": 6}

    # ═══ Maki 符号表 (与前端 maki_symbols.json 同源) ═══
    import json as _json
    _sym_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "frontend", "maki_symbols.json")
    _maki = {}
    try:
        with open(os.path.normpath(_sym_path), encoding="utf-8") as _f:
            _maki = _json.load(_f).get("symbols", {})
    except Exception as _e:
        logger.warning(f"maki_symbols.json load failed: {_e}")

    # 布点候选白名单 (与前端 NON_PLACABLE 互补: 这些项才可布点)
    _non_placable = {"P2-02","P2-03","P2-04","P2-05","P2-06","P3-01","P3-02","P3-03",
                     "P3-04","P3-05","P3-06","P5-02","P5-03","P6-01","P6-02","P6-04"}

    def _svg_path_to_polylines(path_d: str, scale: float = 0.4) -> list:
        """Maki SVG path → 折线点列表 (相对坐标, 中心在原点, 单位尺寸)"""
        try:
            from svgpathtools import parse_path
            p = parse_path(path_d)
            pts = []
            for seg in p:
                n = max(2, int(seg.length() / 0.8) + 1)
                for i in range(n):
                    z = seg.point(i / n)
                    pts.append((z.real, z.imag))
            # 归一化到中心
            if not pts:
                return []
            xs = [q[0] for q in pts]; ys = [q[1] for q in pts]
            cx = (min(xs) + max(xs)) / 2; cy = (min(ys) + max(ys)) / 2
            w = max(max(xs) - min(xs), max(ys) - min(ys), 1e-6)
            s = scale / w
            return [((x - cx) * s, (y - cy) * s) for x, y in pts]
        except Exception:
            return []

    # ═══ 设施布点: 每设施独立图层 + Maki 符号 (P0: 支持一设施多实例 placements) ═══
    # 每个标准项一个图层: TAF-FACILITY-P1-02-PUBLIC-FOUNTAIN
    layer_sym_cache = {}   # layer name -> block name
    for f in facilities:
        item_id = f.standard_item_id or ""
        if item_id in _non_placable:
            continue
        sym = _maki.get(item_id)
        # P0 多实例: 优先读 placements; 空则回退旧 f.position (兼容既有数据)
        points = []
        pls = getattr(f, "placements", None) or []
        for pl in pls:
            p = pl.position or {}
            if p.get("x") is not None and p.get("y") is not None:
                points.append((float(p["x"]), float(p["y"]), pl.seq))
        if not points:
            pos = f.position or {}
            if pos.get("x") is None or pos.get("y") is None:
                continue  # 未布点
            points.append((float(pos["x"]), float(pos["y"]), 1))
        cat = (f.category or "P1").upper()
        color = cat_colors.get(cat, 7)
        layer_name = sym["layer"] if sym else f"TAF-FACILITY-{item_id}"
        if layer_name not in doc.layers:
            doc.layers.add(name=layer_name, color=color)

        if sym and sym.get("path"):
            # 生成/复用 block
            block_name = f"SYM_{item_id.replace('-', '_')}"
            if block_name not in doc.blocks:
                blk = doc.blocks.new(name=block_name)
                poly = _svg_path_to_polylines(sym["path"], scale=6)
                if len(poly) >= 3:
                    blk.add_lwpolyline(poly, close=True, dxfattribs={"color": color, "layer": "0"})
            for x, y, seq in points:
                msp.add_blockref(block_name, (x, y), dxfattribs={"layer": layer_name})
        else:
            # fallback: 圆
            for x, y, seq in points:
                msp.add_circle(center=(x, y), radius=4, dxfattribs={"layer": layer_name, "color": color})
        # 编号标签 (独立 TAF-LABEL 层, 便于统一关闭); 多实例带序号
        label_id = item_id.replace("P", "").replace("-", "")[:6]
        if "TAF-LABEL" not in doc.layers:
            doc.layers.add(name="TAF-LABEL", color=colors.CYAN)
        for x, y, seq in points:
            txt = label_id if len(points) <= 1 else f"{label_id}-{seq}"
            msp.add_text(txt, dxfattribs={
                "layer": "TAF-LABEL", "color": colors.CYAN, "height": 6,
            }).set_placement((x + 6, y + 4))

    # ═══ Legend: 表格, 一行一图例 (旧层 + 新布点层) ═══
    legend_x, legend_y = 50, 50
    if "TAF-LEGEND" not in doc.layers:
        doc.layers.add(name="TAF-LEGEND", color=colors.WHITE)
    msp.add_text("TAF 底图与设施布点图例", dxfattribs={
        "layer": "TAF-LEGEND", "color": colors.WHITE, "height": 14,
    }).set_placement((legend_x, legend_y + 6))

    # 表头
    row_h = 14
    hy = legend_y - 10
    msp.add_text("图层", dxfattribs={"layer": "TAF-LEGEND", "color": 3, "height": 7}).set_placement((legend_x + 4, hy))
    msp.add_text("图例", dxfattribs={"layer": "TAF-LEGEND", "color": 3, "height": 7}).set_placement((legend_x + 120, hy))
    msp.add_text("说明", dxfattribs={"layer": "TAF-LEGEND", "color": 3, "height": 7}).set_placement((legend_x + 170, hy))
    hy -= row_h

    # 表格线
    def _draw_legend_row(y, swatch_draw, layer_name, desc, color=colors.WHITE):
        # 行分隔线
        msp.add_line(start=(legend_x, y - 2), end=(legend_x + 260, y - 2),
                     dxfattribs={"layer": "TAF-LEGEND", "color": 8})
        msp.add_text(layer_name, dxfattribs={"layer": "TAF-LEGEND", "color": color, "height": 6}
                     ).set_placement((legend_x + 4, y - 5))
        msp.add_text(desc, dxfattribs={"layer": "TAF-LEGEND", "color": colors.WHITE, "height": 6}
                     ).set_placement((legend_x + 170, y - 5))
        swatch_draw(legend_x + 128, y - 3)

    def _swatch_circle(cx, cy, r=3, color=7):
        msp.add_circle(center=(cx, cy), radius=r, dxfattribs={"layer": "TAF-LEGEND", "color": color})

    def _swatch_line(cx, cy, color=7):
        msp.add_line(start=(cx - 4, cy), end=(cx + 4, cy), dxfattribs={"layer": "TAF-LEGEND", "color": color})

    def _swatch_symbol(cx, cy, sym, color):
        pts = _svg_path_to_polylines(sym["path"], scale=5)
        if len(pts) >= 3:
            msp.add_lwpolyline([(cx + qx, cy + qy) for qx, qy in pts], close=True,
                               dxfattribs={"layer": "TAF-LEGEND", "color": color})

    # 旧底图空间图层
    _base_layers = [
        ("TAF-BOUNDARY", "红线边界", 1),
        ("TAF-BUILDING", "建筑", 2),
        ("TAF-CHANNEL", "通道/走廊", 30),
        ("TAF-ROAD", "道路", 5),
        ("TAF-GREEN", "绿地", 3),
        ("TAF-NODE", "节点/广场", 4),
        ("TAF-FACADE", "立面", 6),
        ("BASEMAP", "原始底图", 7),
    ]
    for nm, desc, c in _base_layers:
        if nm in doc.layers:
            _draw_legend_row(hy, lambda cx, cy, c=c: _swatch_line(cx, cy, c), nm, desc, c)
            hy -= row_h

    # 布点符号层 (按 maki 顺序)
    _fac_by_item = {f.standard_item_id: f for f in facilities if f.standard_item_id not in _non_placable}
    for item_id, sym in _maki.items():
        if item_id not in _fac_by_item:
            continue
        cat = item_id.split("-")[0]
        c = cat_colors.get(cat, 7)
        f = _fac_by_item[item_id]
        _draw_legend_row(hy, lambda cx, cy, s=sym, c=c: _swatch_symbol(cx, cy, s, c),
                         sym["layer"], f"{item_id} {f.name}", c)
        hy -= row_h

    # 图名
    msp.add_text(f"{project.name} — 设施布点图 ({project.code})", dxfattribs={
        "layer": "TAF-LEGEND", "color": colors.WHITE, "height": 16,
    }).set_placement((legend_x, legend_y + 26))


    tmp = tempfile.NamedTemporaryFile(suffix=".dxf", delete=False)
    tmp_path = tmp.name
    tmp.close()
    doc.saveas(tmp_path)
    with open(tmp_path, "rb") as f:
        dxf_data = f.read()
    os.unlink(tmp_path)
    return dxf_data


def _generate_layout_dxf_inline(project, standard, facilities, spaces, basemap, output_path):
    """内联版：打包器调用，生成 DXF 保存到指定路径"""
    dxf_data = _build_layout_dxf_core(project, standard, facilities, spaces, basemap)
    with open(output_path, "wb") as f:
        f.write(dxf_data)


@router.post("/{project_id}/deliverables/layout")
async def generate_layout_dxf(
    project_id: UUID,
    user: dict = Depends(get_current_user),
    db: AsyncSession = Depends(get_db),
):
    """在 DXF 底图上标注设施位置，输出策划级图纸"""
    project = await _get_project(project_id, db)
    standard = await _get_standard(project, db)
    facilities = await _get_facilities(project_id, db)

    bm_result = await db.execute(
        select(Basemap).where(
            Basemap.project_id == project_id,
            Basemap.file_type == "dxf",
        ).order_by(Basemap.created_at.desc()).limit(1)
    )
    basemap = bm_result.scalar_one_or_none()

    space_result = await db.execute(
        select(Space).where(Space.project_id == project_id)
    )
    spaces = list(space_result.scalars().all())

    dxf_data = _build_layout_dxf_core(project, standard, facilities, spaces, basemap)

    output = io.BytesIO(dxf_data)
    output.seek(0)

    from urllib.parse import quote
    filename = f"{project.code}_设施布点图.dxf"
    return StreamingResponse(
        output,
        media_type="application/octet-stream",
        headers={"Content-Disposition": f"attachment; filename*=UTF-8''{quote(filename)}"},
    )
