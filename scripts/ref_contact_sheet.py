#!/usr/bin/env python3
"""图库 contact sheet 审查: 下载某项目录全部参考图 → 拼接缩略图网格(带编号) 供 vision 判定室内/户外"""
import subprocess, urllib.parse, re, os, sys
from PIL import Image, ImageDraw

U = 'drin@vip.qq.com'; P = 'anyhfz69pcxzs7dw'
B = 'https://dav.jianguoyun.com/dav/01_CURR_PRJ/2026-16 XING SHUN LI/DELIVERABLES/FACILITIES'
item = sys.argv[1]            # e.g. P1-02_公共饮水点
outdir = '/tmp/refsheets'
os.makedirs(outdir, exist_ok=True)

def curl(args, timeout=40):
    return subprocess.run(['curl', '-s', '-u', f'{U}:{P}'] + args, capture_output=True, text=True, timeout=timeout)

url = urllib.parse.quote(f'{B}/{item}/参考图片', safe=':/')
r = curl(['-X', 'PROPFIND', url, '-H', 'Depth: 1', '--max-time', '30'])
hrefs = [urllib.parse.unquote(h) for h in re.findall(r'<d:href>([^<]+)</d:href>', r.stdout) if not h.endswith('/')]
names = [h.split('/')[-1] for h in hrefs]
print('files:', len(names))
imgs = []
for i, fn in enumerate(names):
    curl(['-L', urllib.parse.quote(f'{B}/{item}/参考图片/{fn}', safe=':/'), '-o', f'/tmp/refsheet_tmp/{i}.img', '--max-time', '40'])
    p = f'/tmp/refsheet_tmp/{i}.img'
    try:
        im = Image.open(p).convert('RGB')
        im.thumbnail((200, 200))
        imgs.append((fn, im))
    except Exception as e:
        print('  open fail', fn, e)
    os.remove(p)
if not imgs:
    print('no images'); sys.exit(1)
cols = 5
th = 210
cell_w = max((im.width for _, im in imgs), default=200) + 14
rows = (len(imgs) + cols - 1) // cols
W = cols * cell_w
H = rows * (th + 4) + 6
sheet = Image.new('RGB', (W, H), (245, 245, 245))
dr = ImageDraw.Draw(sheet)
for idx, (fn, im) in enumerate(imgs):
    c, rr = idx % cols, idx // cols
    x, y = c * cell_w + 4, rr * (th + 4) + 4
    sheet.paste(im, (x, y))
    dr.rectangle([x - 2, y - 2, x + im.width + 1, y + im.height + 1], outline=(200, 0, 0), width=2)
    dr.text((x, y + im.height + 2), f'#{idx} {fn[:22]}', fill=(0, 0, 0))
out = f'{outdir}/{item}.png'
sheet.save(out)
print('sheet saved:', out, imgs[0][1].size, 'x', sheet.size)
# 编号对照 (idx -> filename)
with open(f'{outdir}/{item}.txt', 'w') as f:
    for idx, (fn, _) in enumerate(imgs):
        f.write(f'#{idx}\t{fn}\n')
print('map saved')
