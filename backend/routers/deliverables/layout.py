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

    facility_positions = []
    cat_counters = {}
    for f in facilities:
        cat = f.category or "P1"
        cat_counters.setdefault(cat, 0)
        idx = cat_counters[cat]
        pos_rules = {
            "P1": ["building", "channel"], "P2": ["building", "facade"],
            "P3": ["node"], "P4": ["green", "channel"],
            "P5": ["node", "channel"], "P6": ["building", "facade"],
        }
        space_types = pos_rules.get(cat, ["building", "channel"])
        chosen_layer = None
        for st in space_types:
            target_layer = type_to_layer.get(st)
            if target_layer and target_layer in space_centers:
                chosen_layer = target_layer
                break
        base_x, base_y = space_centers.get(chosen_layer, (400, 250)) if chosen_layer else (400, 250)
        col = idx % 5
        row = idx // 5
        x = base_x + col * 35 - (5 * 35 // 2)
        y = base_y + row * 25
        facility_positions.append({
            "facility": f, "x": x, "y": y, "cat": cat, "color": cat_colors.get(cat, 7),
        })

    for fp in facility_positions:
        f = fp["facility"]
        x, y = fp["x"], fp["y"]
        color = fp["color"]
        cat = fp["cat"]
        if cat == "P1":
            msp.add_lwpolyline([(x-6,y-6),(x+6,y-6),(x+6,y+6),(x-6,y+6)], close=True,
                               dxfattribs={"layer": "TAF-FACILITY", "color": color})
            hatch = msp.add_hatch(color=color, dxfattribs={"layer": "TAF-FACILITY"})
            hatch.paths.add_polyline_path([(x-5,y-5),(x+5,y-5),(x+5,y+5),(x-5,y+5)], is_closed=True)
        elif cat == "P2":
            msp.add_circle(center=(x, y), radius=6, dxfattribs={"layer": "TAF-FACILITY", "color": color})
            msp.add_circle(center=(x, y), radius=3, dxfattribs={"layer": "TAF-FACILITY", "color": color})
        elif cat == "P3":
            pts = [(x,y-7),(x+6,y+5),(x-6,y+5)]
            msp.add_lwpolyline(pts, close=True, dxfattribs={"layer": "TAF-FACILITY", "color": color})
            hatch = msp.add_hatch(color=color, dxfattribs={"layer": "TAF-FACILITY"})
            hatch.paths.add_polyline_path(pts, is_closed=True)
        elif cat == "P4":
            pts4 = [(x+6*math.cos(2*math.pi*i/5), y+6*math.sin(2*math.pi*i/5)) for i in range(5)]
            msp.add_lwpolyline(pts4, close=True, dxfattribs={"layer": "TAF-FACILITY", "color": color})
            hatch = msp.add_hatch(color=color, dxfattribs={"layer": "TAF-FACILITY"})
            hatch.paths.add_polyline_path(pts4, is_closed=True)
        elif cat == "P5":
            pts5 = [(x,y-7),(x+5,y),(x,y+7),(x-5,y)]
            msp.add_lwpolyline(pts5, close=True, dxfattribs={"layer": "TAF-FACILITY", "color": color})
            hatch = msp.add_hatch(color=color, dxfattribs={"layer": "TAF-FACILITY"})
            hatch.paths.add_polyline_path(pts5, is_closed=True)
        else:
            msp.add_circle(center=(x, y), radius=6, dxfattribs={"layer": "TAF-FACILITY", "color": color})
            hatch = msp.add_hatch(color=color, dxfattribs={"layer": "TAF-FACILITY"})
            hatch.paths.add_polyline_path([(x-5,y-5),(x+5,y-5),(x+5,y+5),(x-5,y+5)], is_closed=True)
        label_id = f.standard_item_id.replace("P", "").replace("-", "")[:6]
        msp.add_text(label_id, dxfattribs={
            "layer": "TAF-LABEL", "color": colors.CYAN, "height": 8,
        }).set_placement((x + 9, y + 3))
        if f.status in ("confirmed", "installed"):
            msp.add_line(start=(x, y-7), end=(x, y-16), dxfattribs={"layer": "TAF-FACILITY", "color": 3})

    legend_x, legend_y = 50, 50
    msp.add_text("TAF 设施布点图例", dxfattribs={
        "layer": "TAF-LEGEND", "color": colors.WHITE, "height": 12,
    }).set_placement((legend_x, legend_y))
    for i, (cat, name) in enumerate(cat_names.items()):
        ly = legend_y - 18 - i * 16
        color = cat_colors.get(cat, 7)
        if cat == "P1":
            msp.add_lwpolyline([(legend_x+1,ly-4),(legend_x+9,ly-4),(legend_x+9,ly+4),(legend_x+1,ly+4)], close=True,
                               dxfattribs={"layer": "TAF-LEGEND", "color": color})
        elif cat == "P2":
            msp.add_circle(center=(legend_x+5, ly), radius=4, dxfattribs={"layer": "TAF-LEGEND", "color": color})
            msp.add_circle(center=(legend_x+5, ly), radius=2, dxfattribs={"layer": "TAF-LEGEND", "color": color})
        elif cat == "P3":
            pts = [(legend_x+5,ly-5),(legend_x+10,ly+3),(legend_x,ly+3)]
            msp.add_lwpolyline(pts, close=True, dxfattribs={"layer": "TAF-LEGEND", "color": color})
        elif cat == "P4":
            pts4 = [(legend_x+5+4*math.cos(2*math.pi*i/5), ly+4*math.sin(2*math.pi*i/5)) for i in range(5)]
            msp.add_lwpolyline(pts4, close=True, dxfattribs={"layer": "TAF-LEGEND", "color": color})
        elif cat == "P5":
            pts5 = [(legend_x+5,ly-5),(legend_x+9,ly),(legend_x+5,ly+5),(legend_x+1,ly)]
            msp.add_lwpolyline(pts5, close=True, dxfattribs={"layer": "TAF-LEGEND", "color": color})
        else:
            msp.add_circle(center=(legend_x+5, ly), radius=4, dxfattribs={"layer": "TAF-LEGEND", "color": color})
        msp.add_text(f"{cat}: {name}", dxfattribs={
            "layer": "TAF-LEGEND", "color": colors.WHITE, "height": 8,
        }).set_placement((legend_x + 18, ly - 2))

    msp.add_text(f"{project.name} — 设施布点图 ({project.code})", dxfattribs={
        "layer": "TAF-LEGEND", "color": colors.WHITE, "height": 16,
    }).set_placement((legend_x, legend_y + 30))

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
