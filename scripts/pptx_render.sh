#!/usr/bin/env bash
# 本地渲染自检: pptx → pdf → 指定页 png (改 PPT 后必用, 代替盲改)
# 用法: bash pptx_render.sh <input.pptx> <outdir> [页号列表如 5,6]
set -e
IN="$1"; OUTD="$2"; PAGES="${3:-}"
[ -f "$IN" ] || { echo "no input: $IN"; exit 1; }
mkdir -p "$OUTD"
BASE=$(basename "$IN" .pptx)
timeout 300 soffice --headless --convert-to pdf --outdir "$OUTD" "$IN" >/dev/null 2>&1
PDF="$OUTD/$BASE.pdf"
[ -f "$PDF" ] || { echo "convert failed"; exit 1; }
if [ -n "$PAGES" ]; then
  for p in ${PAGES//,/ }; do
    timeout 200 pdftoppm -f "$p" -l "$p" -r 110 -png "$PDF" "$OUTD/page" >/dev/null 2>&1
    echo "page $p -> $OUTD/page-$p.png"
  done
else
  timeout 200 pdftoppm -r 80 -png "$PDF" "$OUTD/page" >/dev/null 2>&1
  echo "all pages -> $OUTD/page-*.png"
fi
