#!/usr/bin/env python3
"""全量 SVG 重生成 (2px pad 版): 27 图"""
import sys, json
sys.path.insert(0, '/root/TAF/scripts')
import export_figures as ef
ef.maki = json.load(open(ef.MAKI_JSON, encoding='utf-8'))['symbols']
ef.placements = json.load(open(ef.PLACE_JSON, encoding='utf-8'))
ents = ef.load_dxf()
D = ef.OUT_DIR
modes = [('composite', None), ('basemap', None), ('basemap-clean', None)]
for L in ['TAF-BOUNDARY', 'TAF-BUILDING', 'TAF-CHANNEL', 'TAF-NODE', 'TAF-GREEN', 'TAF-FACADE']:
    modes.append(('maplayer-' + L, None))
items = [f['standard_item_id'] for f in ef.placements['facilities'] if f['placements']]
for it in items:
    modes.append(('single', it))
for i, (m, only) in enumerate(modes):
    ef.build(ents, ef.placements, m, only_item=only, outdir=D)
    print(f'[{i+1}/{len(modes)}] {m}')
print('ALL SVG DONE', len(modes))
