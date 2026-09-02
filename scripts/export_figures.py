#!/usr/bin/env python3
"""TAF 生产图纸 SVG 导出器 (原型)
从用户底图 DXF + DB 点位 → 单一 SVG(线稿, 透明背景, 以 TAF-DRAWING_BORDER 为图幅边界)
模式: composite(全底图+全点位) / basemap(仅底图) / layer-<ITEM>(仅该点位层+图框)
"""
import json, math, os, re, sys

DXF_PATH = '/data/disk1/wwwroot/taf/uploads/550e8400-e29b-41d4-a716-446655440001/20260902_LAYOUT_FOR_IMPORT_ORTHO.dxf'
PLACE_JSON = '/root/TAF/scripts/backup/placements_OS-NC-2026-001_20260903.json'
MAKI_JSON = '/root/TAF/frontend/maki_symbols.json'
OUT_DIR = '/data/disk1/wwwroot/taf/exports_dev'
OUT_H = 2160          # 🔴 页面基准: 高度 2160 (宽度等比), 与 PPTX 3840×2160 页匹配
DESIGN_W = 3840       # 观感设计基准宽 (字号/线宽按此定义, 输出时等比缩放)

# 图层配色 (深底可读线稿色, 与前端 LAYER_COLORS 一致)
LAYER_COLORS = {
    'TAF-BOUNDARY': '#ff4d4d', 'BOUNDARY': '#ff4d4d',
    'TAF-BUILDING': '#ffd60a', 'BUILDING': '#ffd60a',
    'TAF-BUILDING_NUMBER': '#8a93a5',
    'TAF-CHANNEL': '#ff9500', 'CHANNEL': '#ff9500',
    'TAF-GREEN': '#4cd964', 'GREEN': '#4cd964',
    'TAF-ROAD': '#4d7cff', 'ROAD': '#4d7cff',
    'TAF-NODE': '#00e5ff', 'NODE': '#00e5ff',
    'TAF-FACADE': '#ff5ea8', 'FACADE': '#ff5ea8',
    'TAF-BASEMAP': '#9aa3b2', 'BASEMAP': '#9aa3b2',
    'TAF-DRAWING_BORDER': '#e8e8f0',
}
DEFAULT_LAYER_COLOR = '#9aa3b2'
CAT_COLORS = {'P1': '#4f8cff', 'P2': '#67c23a', 'P3': '#e6a23c', 'P4': '#c97dff', 'P5': '#f56c6c', 'P6': '#8b8fa3'}
# 线宽优先级: 语义主层粗, 底图次之
LAYER_LW = {'TAF-BUILDING': 3.2, 'TAF-BOUNDARY': 3.0, 'TAF-CHANNEL': 2.6, 'TAF-NODE': 2.6,
            'TAF-FACADE': 2.4, 'TAF-GREEN': 2.4, 'TAF-ROAD': 2.4,
            'TAF-DRAWING_BORDER': 4.0, 'TAF-BASEMAP': 1.1, 'BASEMAP': 1.1}


def clean_mtext(raw):
    if not raw:
        return ''
    t = str(raw)
    t = re.sub(r'\{[^}]*\}', lambda m: m.group(0)[m.group(0).find(';')+1:-1] if ';' in m.group(0) else '', t)
    t = re.sub(r'\\[a-zA-Z][^;]*;', '', t)
    t = re.sub(r'[\\\x00-\x08\x0b\x0c\x0e-\x1f]', '', t)
    return t.replace('\\P', '\n').strip()


class SvgBuilder:
    def __init__(self, minx, miny, maxx, maxy, pad_frac=0.005):
        pad = max(maxx-minx, maxy-miny) * pad_frac
        self.x0, self.y0 = minx - pad, miny - pad
        self.x1, self.y1 = maxx + pad, maxy + pad
        self.w_w = self.x1 - self.x0
        self.h_w = self.y1 - self.y0
        # 🔴 基准: 高度 OUT_H=2160, 宽度等比 (与 PPTX 3840×2160 页按高度匹配)
        self.out_h = OUT_H
        self.out_w = max(1, int(round(self.w_w * OUT_H / self.h_w)))
        self.k = self.out_w / DESIGN_W   # 观感系数: 字号/线宽以 3840 宽设计, 输出等比缩放
        self.parts = []

    def X(self, x):
        return (x - self.x0) * self.out_w / self.w_w

    def Y(self, y):
        return (self.y1 - y) * self.out_w / self.w_w

    def line(self, x1, y1, x2, y2, color, lw):
        self.parts.append(f'<line x1="{self.X(x1):.2f}" y1="{self.Y(y1):.2f}" x2="{self.X(x2):.2f}" y2="{self.Y(y2):.2f}" stroke="{color}" stroke-width="{lw*self.k:.2f}" stroke-linecap="round"/>')

    def poly(self, pts, color, lw, closed=False):
        if len(pts) < 2:
            return
        d = 'M' + ' L'.join(f'{self.X(px):.2f},{self.Y(py):.2f}' for px, py in pts)
        if closed:
            d += ' Z'
        self.parts.append(f'<path d="{d}" fill="none" stroke="{color}" stroke-width="{lw*self.k:.2f}" stroke-linejoin="round"/>')

    def circle(self, cx, cy, r, color, lw):
        self.parts.append(f'<circle cx="{self.X(cx):.2f}" cy="{self.Y(cy):.2f}" r="{r*self.out_w/self.w_w:.2f}" fill="none" stroke="{color}" stroke-width="{lw*self.k:.2f}"/>')

    def arc(self, cx, cy, r, a0, a1, color, lw):
        R = r * self.out_w / self.w_w
        x0, y0 = self.X(cx + r*math.cos(a0)), self.Y(cy + r*math.sin(a0))
        x1, y1 = self.X(cx + r*math.cos(a1)), self.Y(cy + r*math.sin(a1))
        large = 1 if (a1 - a0) % (2*math.pi) > math.pi else 0
        self.parts.append(f'<path d="M{x0:.2f},{y0:.2f} A{R:.2f},{R:.2f} 0 {large} 0 {x1:.2f},{y1:.2f}" fill="none" stroke="{color}" stroke-width="{lw*self.k:.2f}"/>')

    def text(self, x, y, s, color, size, anchor='start', weight='normal', rotate=0):
        if not s:
            return
        lines = s.split('\n')
        size2 = size * self.k
        sx, sy = self.X(x), self.Y(y)
        ts = ''.join(f'<tspan x="{sx:.2f}" dy="{0 if i==0 else size2+2}">{_esc(t)}</tspan>' for i, t in enumerate(lines))
        rot = f' transform="rotate({-math.degrees(rotate) if rotate else 0} {sx:.2f} {sy:.2f})"'
        self.parts.append(f'<text x="{sx:.2f}" y="{sy:.2f}"{rot} fill="{color}" font-family="sans-serif" font-size="{size2:.2f}" font-weight="{weight}">{ts}</text>')

    def maki(self, cx, cy, path_d, color, size):
        s = (size * self.k) / 15.0
        x, y = self.X(cx), self.Y(cy)
        self.parts.append(f'<g transform="translate({x:.2f} {y:.2f}) scale({s:.3f}) translate(-7.5 -7.5)"><path d="{path_d}" fill="{color}" stroke="rgba(0,0,0,0.5)" stroke-width="0.6"/></g>')

    def svg(self, title):
        head = (f'<svg xmlns="http://www.w3.org/2000/svg" width="{self.out_w}" height="{self.out_h}" '
                f'viewBox="0 0 {self.out_w} {self.out_h}"><title>{_esc(title)}</title>')
        return head + '\n'.join(self.parts) + '</svg>'


def _esc(s):
    return (str(s).replace('&', '&amp;').replace('<', '&lt;').replace('>', '&gt;')
            .replace('"', '&quot;').replace("'", '&#39;'))


def load_dxf():
    import ezdxf
    doc = ezdxf.readfile(DXF_PATH)
    ents = []  # (layer, type, payload, color_override)
    for e in doc.modelspace():
        lt = e.dxftype()
        layer = e.dxf.layer
        if lt in ('LINE',):
            s, en = e.dxf.start, e.dxf.end
            ents.append((layer, 'line', (s.x, s.y, en.x, en.y)))
        elif lt == 'LWPOLYLINE':
            pts = [(p[0], p[1]) for p in e.get_points()]
            ents.append((layer, 'poly', (pts, bool(e.closed))))
        elif lt == 'POLYLINE':
            v = [ (x.dxf.location.x, x.dxf.location.y) for x in e.vertices ]
            ents.append((layer, 'poly', (v, e.is_closed)))
        elif lt == 'CIRCLE':
            c, r = e.dxf.center, e.dxf.radius
            ents.append((layer, 'circle', (c.x, c.y, r)))
        elif lt == 'ARC':
            c, r = e.dxf.center, e.dxf.radius
            ents.append((layer, 'arc', (c.x, c.y, r, math.radians(e.dxf.start_angle), math.radians(e.dxf.end_angle))))
        elif lt == 'MTEXT':
            ents.append((layer, 'mtext', (e.dxf.insert.x, e.dxf.insert.y, e.text)))
        elif lt == 'TEXT':
            ents.append((layer, 'text', (e.dxf.insert.x, e.dxf.insert.y, e.dxf.text, e.dxf.rotation or 0)))
        # INSERT(块引用)暂不展开
    return ents


def border_bbox(ents):
    xs, ys = [], []
    for layer, typ, pl in ents:
        if layer == 'TAF-DRAWING_BORDER':
            if typ == 'poly':
                for px, py in pl[0]:
                    xs.append(px); ys.append(py)
            elif typ == 'line':
                xs += [pl[0], pl[2]]; ys += [pl[1], pl[3]]
    if xs:
        return min(xs), min(ys), max(xs), max(ys)
    # fallback 全部实体 bbox
    for layer, typ, pl in ents:
        if typ == 'poly':
            for px, py in pl[0]:
                xs.append(px); ys.append(py)
        elif typ == 'line':
            xs += [pl[0], pl[2]]; ys += [pl[1], pl[3]]
        elif typ == 'circle':
            xs += [pl[0]-pl[2], pl[0]+pl[2]]; ys += [pl[1]-pl[2], pl[1]+pl[2]]
    return min(xs), min(ys), max(xs), max(ys)


def build(ents, placements, mode='composite', only_item=None, only_layer=None, fname_map=None, outdir=OUT_DIR):
    """mode: composite | basemap | basemap-clean | maplayer-<LAYER> | single(<only_item>点位层)
    basemap-clean: 仅无彩色基础层 (TAF-BASEMAP/TAF-BUILDING_NUMBER/TAF-DRAWING_BORDER/0层)
    maplayer: 指定彩色语义底图图层 + 图框 (定位校准)
    single: 仅图框 + 该点位层"""
    CLEAN = {'TAF-BASEMAP', 'TAF-BUILDING_NUMBER', 'TAF-DRAWING_BORDER', '0', 'BASEMAP'}
    is_clean = (mode == 'basemap-clean')
    is_maplayer = mode.startswith('maplayer-')
    if is_maplayer and not only_layer:
        only_layer = mode[len('maplayer-'):]
    minx, miny, maxx, maxy = border_bbox(ents)
    b = SvgBuilder(minx, miny, maxx, maxy)
    lw = LAYER_LW

    def keep_layer(layer):
        if is_clean:
            return layer in CLEAN
        if is_maplayer:
            return layer == only_layer or layer == 'TAF-DRAWING_BORDER'
        if only_item:  # single 点位层
            return layer == 'TAF-DRAWING_BORDER'
        if mode == 'basemap' and layer.startswith('TAF-FACILITY'):
            return False
        return True

    for layer, typ, pl in ents:
        if not keep_layer(layer):
            continue
        if layer == 'TAF-DRAWING_BORDER':
            col, w = LAYER_COLORS.get(layer, DEFAULT_LAYER_COLOR), lw.get(layer, 2)
        else:
            col = LAYER_COLORS.get(layer, LAYER_COLORS.get(layer.split('-')[-1], DEFAULT_LAYER_COLOR))
            w = lw.get(layer, 1.6)
        if typ == 'line':
            b.line(*pl, col, w)
        elif typ == 'poly':
            b.poly(pl[0], col, w, pl[1])
        elif typ == 'circle':
            b.circle(*pl, col, w)
        elif typ == 'arc':
            b.arc(*pl, col, w)
        elif typ in ('mtext', 'text'):
            pass  # 文字在第二遍绘制(置顶)

    # 文字置顶 (建筑编号/底图标注)
    for layer, typ, pl in ents:
        if not keep_layer(layer):
            continue
        col = LAYER_COLORS.get(layer, LAYER_COLORS.get(layer.split('-')[-1], DEFAULT_LAYER_COLOR))
        if typ == 'mtext':
            txt = clean_mtext(pl[2])
            if not txt:
                continue
            size = 22 if layer == 'TAF-BUILDING_NUMBER' else 15
            col = '#cfd6e4' if layer == 'TAF-BUILDING_NUMBER' else col
            b.text(pl[0], pl[1], txt, col, size)
        elif typ == 'text':
            b.text(pl[0], pl[1], clean_mtext(pl[2]), col, 15, rotate=pl[3])

    # 点位: 仅 composite(综合) 与 single(点位层) 模式
    if mode == 'composite' or only_item:
        for fac in placements['facilities']:
            item = fac['standard_item_id']
            if only_item and item != only_item:
                continue
            sym = maki.get(item)
            color = CAT_COLORS.get(item.split('-')[0], '#ffffff')
            base = item.replace('P', '').replace('-', '')
            for p in fac['placements']:
                x, y = float(p['x']), float(p['y'])
                seq = p['seq']
                if sym:
                    b.maki(x, y, sym['path'], color, 42)
                else:
                    b.circle(x, y, 14, color, 3)
                if seq > 1:
                    b.text(x + 24, y + 24, f'{base}-{seq}', color, 17, weight='bold')
                else:
                    b.text(x + 24, y + 24, base, color, 17, weight='bold')

    os.makedirs(outdir, exist_ok=True)
    if only_item:
        tag = f'layer-{only_item}'
    elif is_maplayer:
        tag = f'map-{only_layer}'
    elif is_clean:
        tag = 'basemap-clean'
    elif mode == 'composite':
        tag = 'composite'
    else:
        tag = 'basemap'
    fn = os.path.join(outdir, f'{tag}.svg')
    open(fn, 'w', encoding='utf-8').write(b.svg(tag))
    print('SVG:', fn, f'{b.out_w}x{b.out_h}')
    return fn


if __name__ == '__main__':
    global maki
    maki = json.load(open(MAKI_JSON, encoding='utf-8'))['symbols']
    placements = json.load(open(PLACE_JSON, encoding='utf-8'))
    ents = load_dxf()
    print('entities:', len(ents), '| border bbox:', border_bbox(ents))
    build(ents, placements, 'composite')
    build(ents, placements, 'basemap')
    build(ents, placements, 'basemap-clean')
    build(ents, placements, 'maplayer-TAF-BUILDING')
    build(ents, placements, 'maplayer-TAF-CHANNEL')
    build(ents, placements, 'single', only_item='P1-02')
