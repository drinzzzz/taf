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

    cat_colors = {"P1": 1, "P2": 2, "P3": 3, "P4": 4, "P5": 5, "P6": 6}   # 遗留兜底(不再使用, 见 _item_colors)

    # ═══ Maki 符号表 (与前端 maki_symbols.json 同源) ═══
    import json as _json
    _sym_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "frontend", "maki_symbols.json")
    _maki = {}
    try:
        with open(os.path.normpath(_sym_path), encoding="utf-8") as _f:
            _maki = _json.load(_f).get("symbols", {})
    except Exception as _e:
        logger.warning(f"maki_symbols.json load failed: {_e}")

    # ═══ 18 项逐项色 (与前端 ITEM_COLORS / PPTX 一致; 单一事实源 scripts/item_color.json) ═══
    _item_color_path = os.path.join(os.path.dirname(__file__), "..", "..", "..", "scripts", "item_color.json")
    _item_colors = {}
    try:
        with open(os.path.normpath(_item_color_path), encoding="utf-8") as _f:
            _item_colors = _json.load(_f)
        # 归一化: 统一带 '#' 前缀 (json 源文件值如 F15555)
        _item_colors = {k: (('#' + v) if (isinstance(v, str) and v and not v.startswith('#')) else v)
                        for k, v in _item_colors.items()}
    except Exception as _e:
        logger.warning(f"item_color.json load failed: {_e}")

    def _hex_int(hexcol):
        """#RRGGBB → ezdxf TrueColor int (R2000+)"""
        h = (hexcol or "").lstrip("#")
        if len(h) != 6:
            return None
        return (int(h[0:2], 16) << 16) | (int(h[2:4], 16) << 8) | int(h[4:6], 16)

    def _tc(entity, hexcol):
        """给实体/图层设 TrueColor (hex), 返回是否成功"""
        v = _hex_int(hexcol)
        if v is None:
            return False
        try:
            entity.dxf.true_color = v
            return True
        except Exception:
            return False

    # 布点候选白名单 (与前端 NON_PLACABLE 互补: 这些项才可布点)
    _non_placable = {"P2-02","P2-03","P2-04","P2-05","P2-06","P3-01","P3-02","P3-03",
                     "P3-04","P3-05","P3-06","P5-02","P5-03","P6-01","P6-02","P6-04"}
    # 区域型标准项 (非点位 → DXF 文字标注, 与前端 AREA_ITEMS 对齐)
    _area_items = {"P1-01": "防滑处理区"}

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
        hexcol = _item_colors.get(item_id)          # 🔴 18 项逐项色 (hex)
        color = 7                                   # ACI 兜底; 视觉以 TrueColor 呈现
        layer_name = sym["layer"] if sym else f"TAF-FACILITY-{item_id}"
        if layer_name not in doc.layers:
            doc.layers.add(name=layer_name, color=color)
            if hexcol:
                _tc(doc.layers.get(layer_name), hexcol)

        # 区域型: 文字标注 (非 blockref/圆)
        if item_id in _area_items:
            area_text = _area_items[item_id]
            for x, y, seq in points:
                t = msp.add_text(area_text, dxfattribs={
                    "layer": layer_name, "color": color, "height": 5,
                }).set_placement((x, y))
                if hexcol:
                    _tc(t, hexcol)
            continue
        if sym and sym.get("path"):
            # 生成/复用 block
            block_name = f"SYM_{item_id.replace('-', '_')}"
            if block_name not in doc.blocks:
                blk = doc.blocks.new(name=block_name)
                poly = _svg_path_to_polylines(sym["path"], scale=6)
                if len(poly) >= 3:
                    pl = blk.add_lwpolyline(poly, close=True, dxfattribs={"color": color, "layer": "0"})
                    if hexcol:
                        _tc(pl, hexcol)
            for x, y, seq in points:
                msp.add_blockref(block_name, (x, y), dxfattribs={"layer": layer_name})
        else:
            # fallback: 圆
            for x, y, seq in points:
                c = msp.add_circle(center=(x, y), radius=4, dxfattribs={"layer": layer_name, "color": color})
                if hexcol:
                    _tc(c, hexcol)
        # 编号标签 (独立 TAF-LABEL 层, 便于统一关闭); 颜色随项 18 色 (TrueColor)
        label_id = item_id.replace("P", "").replace("-", "")[:6]
        if "TAF-LABEL" not in doc.layers:
            doc.layers.add(name="TAF-LABEL", color=colors.CYAN)
        for x, y, seq in points:
            txt = label_id if len(points) <= 1 else f"{label_id}-{seq}"
            t = msp.add_text(txt, dxfattribs={
                "layer": "TAF-LABEL", "color": color, "height": 6,
            }).set_placement((x + 6, y + 4))
            if hexcol:
                _tc(t, hexcol)

    # ═══ Legend 完善版: 序号|图层名|线型示例|中文名称|颜色|说明 (一行一层, 图框右侧独立表格) ═══
    # 覆盖: 图纸全部源图层 + 已布点设施层; 中文用 TAF-CN 样式 (txt.shx+gbcbig)
    cn_style = 'TAF-CN'
    if cn_style not in doc.styles:
        doc.styles.new(cn_style, dxfattribs={'font': 'txt.shx', 'bigfont': 'gbcbig.shx'})

    def _add_cn(x, y, h, txt, layer='TAF-LEGEND', color=7):
        t = msp.add_text(txt, dxfattribs={'layer': layer, 'color': color, 'height': h, 'style': cn_style})
        t.set_placement((x, y))
        return t

    # ── 收集每层内容形态 (面/线/圆) 与虚线 ──
    layer_face, layer_line, layer_circle = {}, {}, {}
    for e in msp:
        lay = e.dxf.layer
        lt = e.dxftype()
        if lt == 'LWPOLYLINE':
            (layer_face if e.closed else layer_line)[lay] = True
        elif lt == 'POLYLINE':
            (layer_face if e.is_closed else layer_line)[lay] = True
        elif lt in ('LINE', 'SPLINE', 'ARC'):
            layer_line[lay] = True
        elif lt == 'CIRCLE':
            layer_circle[lay] = True

    def _dashed(lay):
        try:
            return doc.layers.get(lay).dxf.linetype not in (None, 'Continuous')
        except Exception:
            return False

    aci_cn = {1: '红', 2: '黄', 3: '绿', 4: '青', 5: '蓝', 6: '品红', 7: '白', 8: '灰', 9: '浅灰',
              30: '橙', 40: '黄绿', 50: '紫', 140: '深蓝', 250: '深灰'}
    base_order = ['TAF-DRAWING_BORDER', 'TAF-BOUNDARY', 'BOUNDARY', 'TAF-BUILDING', 'TAF-BUILDING_NUMBER',
                  'TAF-CHANNEL', 'TAF-NODE', 'TAF-GREEN', 'TAF-ROAD', 'TAF-FACADE', 'TAF-BASEMAP', 'BASEMAP']
    base_cn = {'TAF-DRAWING_BORDER': '图纸图框边界', 'TAF-BOUNDARY': '红线边界', 'BOUNDARY': '红线边界',
               'TAF-BUILDING': '建筑', 'BUILDING': '建筑', 'TAF-BUILDING_NUMBER': '建筑编号',
               'TAF-CHANNEL': '通道/走廊', 'CHANNEL': '通道/走廊', 'TAF-NODE': '节点/广场', 'NODE': '节点/广场',
               'TAF-GREEN': '绿地', 'GREEN': '绿地', 'TAF-ROAD': '道路', 'ROAD': '道路',
               'TAF-FACADE': '沿街立面', 'FACADE': '沿街立面', 'TAF-BASEMAP': '原始底图', 'BASEMAP': '原始底图'}
    base_desc = {'TAF-DRAWING_BORDER': '图幅边界与定位基准', 'TAF-BOUNDARY': '项目用地红线, 评估/布点范围边界', 'BOUNDARY': '项目用地红线',
                 'TAF-BUILDING': '建筑实体 (室内禁区, 设施布其外沿)', 'TAF-BUILDING_NUMBER': '建筑编号文字',
                 'TAF-CHANNEL': '通道/走廊可通行面', 'TAF-NODE': '节点/广场开放空间', 'TAF-GREEN': '绿地开放空间',
                 'TAF-ROAD': '道路', 'TAF-FACADE': '沿街立面线', 'TAF-BASEMAP': '原始底图参照线', 'BASEMAP': '原始底图参照线'}

    rows = []  # (layer, 中文, aci, kind, 说明)
    seen = set()
    all_layer_names = sorted(l.dxf.name for l in doc.layers)
    for nm in base_order + [n for n in all_layer_names if n not in base_order]:
        if nm == '0' or nm in seen:
            continue
        if nm.startswith('TAF-FACILITY-') or nm in ('TAF-LEGEND', 'TAF-LABEL', 'TAF-FACILITY', 'TAF-CN', 'Defpoints'):
            continue
        seen.add(nm)
        try:
            aci = doc.layers.get(nm).dxf.color
        except Exception:
            aci = 7
        if layer_face.get(nm):
            kind = 'face'
        elif layer_circle.get(nm):
            kind = 'circle'
        else:
            kind = 'line'
        rows.append([nm, base_cn.get(nm, nm), aci, kind, base_desc.get(nm, '底图图层')])

    # 已布点设施层 (按 item 排序)
    fac_meta = {}
    for f in facilities:
        item_id = f.standard_item_id or ''
        if item_id in _non_placable:
            continue
        sym = _maki.get(item_id)
        lname = sym['layer'] if sym else f'TAF-FACILITY-{item_id}'
        cnt = sum(1 for pl in (getattr(f, 'placements', None) or [])
                  if (pl.position or {}).get('x') is not None)
        if not cnt and not (f.position or {}).get('x'):
            continue
        fac_meta[lname] = (item_id, f.name, cnt, sym)
    for lname in sorted(fac_meta):
        item_id, fname, cnt, sym = fac_meta[lname]
        hexv = _item_colors.get(item_id, 7)     # 🔴 18 项逐项色 (hex)
        if item_id in _area_items:
            kind = 'area'
        elif sym and sym.get('path'):
            kind = 'symbol'
        else:
            kind = 'circle'
        rows.append([lname, f'{item_id} {fname}', hexv, kind, f'已布 {cnt} 处'])

    # ── 表格几何: 置于底图图框右侧 ──
    bb = None
    for e in msp:
        if e.dxf.layer != 'TAF-DRAWING_BORDER':
            continue
        lt = e.dxftype()
        xs2 = ys2 = None
        if lt == 'LWPOLYLINE':
            pts2 = [(p[0], p[1]) for p in e.get_points()]
            xs2 = [p[0] for p in pts2]; ys2 = [p[1] for p in pts2]
        elif lt == 'LINE':
            xs2 = [e.dxf.start.x, e.dxf.end.x]; ys2 = [e.dxf.start.y, e.dxf.end.y]
        if xs2:
            b = [min(xs2), min(ys2), max(xs2), max(ys2)]
            bb = b if bb is None else [min(bb[0], b[0]), min(bb[1], b[1]), max(bb[2], b[2]), max(bb[3], b[3])]
    if bb is None:
        bb = [0, 0, 5895, 4495]

    lx = bb[2] + 90
    col_seq, col_layer, col_sw, col_cn, col_color, col_desc = 0, 34, 204, 252, 364, 414
    row_h = 13
    y = bb[3] - 30
    _add_cn(lx, y, 16, f'{project.name} — 设施布点图例索引 ({project.code})')
    y -= row_h + 6
    hdr = ['序号', '图层名', '图例', '中文名称', '颜色', '说明']
    hx = [col_seq, col_layer, col_sw, col_cn, col_color, col_desc]
    for i, h in enumerate(hdr):
        _add_cn(lx + hx[i], y - 5, 7, h, color=3)
    y -= row_h
    msp.add_line((lx, y + 3), (lx + 700, y + 3), dxfattribs={'layer': 'TAF-LEGEND', 'color': 8})

    def _swatch(cx, cy, kind, color, layer_name, hexcol=None):
        def _w(e):
            if hexcol:
                _tc(e, hexcol)
            return e
        if kind == 'face':
            _w(msp.add_lwpolyline([(cx - 8, cy - 2.5), (cx + 8, cy - 2.5), (cx + 8, cy + 2.5), (cx - 8, cy + 2.5)],
                               close=True, dxfattribs={'layer': 'TAF-LEGEND', 'color': color}))
            _w(msp.add_line((cx - 8, cy - 2.5), (cx + 8, cy + 2.5), dxfattribs={'layer': 'TAF-LEGEND', 'color': color}))
        elif kind == 'symbol':
            sym = fac_meta.get(layer_name, (None, None, None, None))[3]
            if sym:
                pts3 = _svg_path_to_polylines(sym['path'], scale=3)
                if len(pts3) >= 3:
                    _w(msp.add_lwpolyline([(cx + qx, cy + qy) for qx, qy in pts3], close=True,
                                       dxfattribs={'layer': 'TAF-LEGEND', 'color': color}))
        elif kind == 'area':
            t = _add_cn(cx - 2, cy - 3, 6, '区', color=color)
            if hexcol:
                _tc(t, hexcol)
        elif kind == 'circle':
            _w(msp.add_circle((cx, cy), radius=3, dxfattribs={'layer': 'TAF-LEGEND', 'color': color}))
        else:  # line
            if _dashed(layer_name):
                for dx0 in (-8, -2.5, 3):
                    _w(msp.add_line((cx + dx0, cy), (cx + dx0 + 3.5, cy), dxfattribs={'layer': 'TAF-LEGEND', 'color': color}))
            else:
                _w(msp.add_line((cx - 8, cy), (cx + 8, cy), dxfattribs={'layer': 'TAF-LEGEND', 'color': color}))

    for idx, (layer_name, cn, colv, kind, desc) in enumerate(rows, start=1):
        hexcol = colv if (isinstance(colv, str) and colv.startswith('#')) else None
        dcol = 7 if hexcol else colv
        _add_cn(lx + col_seq, y - 5, 5, str(idx))
        t1 = _add_cn(lx + col_layer, y - 5, 5, layer_name, color=dcol)
        if hexcol: _tc(t1, hexcol)
        _swatch(lx + col_sw + 14, y - 1, kind, dcol, layer_name, hexcol)
        _add_cn(lx + col_cn, y - 5, 5, cn)
        t2 = _add_cn(lx + col_color, y - 5, 5, hexcol if hexcol else f'{colv}{aci_cn.get(colv, "")}', color=dcol)
        if hexcol: _tc(t2, hexcol)
        _add_cn(lx + col_desc, y - 5, 5, desc)
        y -= row_h
    msp.add_line((lx, y + 3 + row_h), (lx + 700, y + 3 + row_h), dxfattribs={'layer': 'TAF-LEGEND', 'color': 8})

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
