#!/usr/bin/env python3
"""TAF 点位符号总览 PPT — 18 图标一页 (黑色正圆底 + 白色图案 + MiSans 标注三行)"""
import sys, json, re
from pptx import Presentation
from pptx.util import Emu, Pt
from pptx.dml.color import RGBColor
from pptx.enum.shapes import MSO_SHAPE
from pptx.oxml.ns import qn

MAKI = json.load(open('/root/TAF/frontend/maki_symbols.json', encoding='utf-8'))['symbols']
# 图标顺序 = 序号升序 (与点位层清单一致)
items = sorted(MAKI.keys())
print('symbol count:', len(items))

EMU = 9525.0
PAGE_W, PAGE_H = 3840, 2160
prs = Presentation()
prs.slide_width = Emu(int(PAGE_W * EMU))
prs.slide_height = Emu(int(PAGE_H * EMU))
slide = prs.slides.add_slide(prs.slide_layouts[6])

def no_shadow(obj):
    try:
        el = obj._element
        st = el.find(qn('p:style'))
        if st is not None:
            el.remove(st)
        for e2 in el.spPr.findall(qn('a:effectLst')):
            el.spPr.remove(e2)
    except Exception:
        pass

def set_font(r, size_pt, color=RGBColor(0x11, 0x11, 0x11), bold=False):
    r.font.size = Pt(size_pt)
    r.font.color.rgb = color
    r.font.name = 'MiSans'          # 🔴 用户指定字体
    r.font.bold = bold
    # 中文字体名 (east asian) 也设 MiSans
    try:
        rPr = r._r.get_or_add_rPr()
        la = rPr.makeelement(qn('a:ea'), {'typeface': 'MiSans'})
        rPr.append(la)
        cs = rPr.makeelement(qn('a:cs'), {'typeface': 'MiSans'})
        rPr.append(cs)
    except Exception:
        pass

def add_text(cx, cy, txt, size_pt, bold=False, w_px=900):
    tb = slide.shapes.add_textbox(Emu(int((cx - w_px / 2) * EMU)), Emu(int(cy * EMU)),
                                  Emu(int(w_px * EMU)), Emu(int((size_pt * 1.6 + 8) * EMU)))
    tf = tb.text_frame
    tf.margin_left = tf.margin_right = tf.margin_top = tf.margin_bottom = Emu(0)
    tf.word_wrap = True
    p = tf.paragraphs[0]
    p.alignment = 2  # center
    r = p.add_run()
    r.text = txt
    set_font(r, size_pt, bold=bold)
    no_shadow(tb)

def split_subpaths(d):
    parts = re.split(r'(?=M)', d)
    return [p for p in parts if p.strip().startswith('M')]

def subpath_polylines(d_sub):
    from svgpathtools import parse_path
    import html
    p = parse_path(html.unescape(d_sub))
    pts = []
    for seg in p:
        n = max(2, int(seg.length() / 0.9) + 1)
        for i in range(n):
            z = seg.point(i / n)
            pts.append((z.real, z.imag))
    return pts

# ── 布局: 4 列 × 5 行 (标题区顶部) ──
TITLE_Y = 60
GRID_TOP = 210
COLS, ROWS = 4, 5
CELL_W, CELL_H = PAGE_W / COLS, (PAGE_H - GRID_TOP) / ROWS
CIRCLE_D = 150            # 正圆直径 px
CIRCLE_D_EMU = Emu(int(CIRCLE_D * EMU))
BLACK = RGBColor(0x00, 0x00, 0x00)
WHITE = RGBColor(0xFF, 0xFF, 0xFF)

# 页标题
add_text(PAGE_W / 2, TITLE_Y, '兴顺里 TAF · 点位符号总览（18 项）', 34, bold=True, w_px=2000)
add_text(PAGE_W / 2, TITLE_Y + 70, '黑色正圆 = 设施图标 · 白色图案 = 布点符号', 18, w_px=1600)

for idx, item in enumerate(items):
    sym = MAKI[item]
    col, row = idx % COLS, idx // COLS
    cx = col * CELL_W + CELL_W / 2
    cy_top = GRID_TOP + row * CELL_H
    cy_circle = cy_top + CELL_H * 0.30          # 圆位: 格上部
    # 1) 黑色正圆底
    circle = slide.shapes.add_shape(MSO_SHAPE.OVAL,
                                    Emu(int((cx - CIRCLE_D / 2) * EMU)),
                                    Emu(int((cy_circle - CIRCLE_D / 2) * EMU)),
                                    CIRCLE_D_EMU, CIRCLE_D_EMU)
    circle.fill.solid()
    circle.fill.fore_color.rgb = BLACK
    circle.line.fill.background()
    no_shadow(circle)
    circle.name = f'circ_{item}'
    # 2) 白色图案 (各 M 子路径闭合折线)
    path_d = sym['path']
    k = (CIRCLE_D * 0.86) / 15.0     # 图案占圆径 ~86%
    for sub in split_subpaths(path_d):
        pts = subpath_polylines(sub)
        if len(pts) < 3:
            continue
        # 以子路径 bbox 中心为原点缩放居中
        xs = [p[0] for p in pts]; ys = [p[1] for p in pts]
        ox_c = (min(xs) + max(xs)) / 2
        oy_c = (min(ys) + max(ys)) / 2
        sp_pts = [(cx + (u - ox_c) * k * EMU, cy_circle + (v - oy_c) * k * EMU) for u, v in pts]
        fb = slide.shapes.build_freeform(int(sp_pts[0][0]), int(sp_pts[0][1]), scale=1.0)
        fb.add_line_segments([(int(a), int(b)) for a, b in sp_pts[1:]], close=True)
        sp = fb.convert_to_shape()
        sp.fill.solid()
        sp.fill.fore_color.rgb = WHITE
        sp.line.color.rgb = WHITE
        sp.line.width = Emu(int(9525 * 0.5))
        no_shadow(sp)
    # 3) 标注三行: 序号(粗) / 中文全称 / 英文图层名
    t0 = cy_circle + CIRCLE_D / 2 + 26
    add_text(cx, t0, item, 26, bold=True)
    add_text(cx, t0 + 52, sym['name_zh'], 20)
    add_text(cx, t0 + 100, sym['layer'], 12, w_px=880)
    # 单元格分隔参考线(浅灰, 便于浏览)
    # (不加线, 保持干净)

out = '/data/disk1/wwwroot/taf/exports_dev/XING_SHUN_LI_TAF_Symbols.pptx'
prs.save(out)
print('saved', out, '| items', len(items))
