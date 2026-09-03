#!/usr/bin/env bash
# ENTH 侧: 必应图片搜索 → 过滤直链 → 下载 3 张 → 直传坚果云 FACILITIES/<项>/参考图片/
# 用法: bash taf_fac_img.sh <查询词(URL已编码)> <目标目录(URL已编码)>
set -u
Q="$1"; DEST="$2"
UA="Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 Chrome/125"
html=$(curl -s -A "$UA" "https://www.bing.com/images/search?q=${Q}&form=HDRSC2&qft=+filterui:imagesize-large" --max-time 40)
# 提取 murl 直链, 过滤扩展名, 去重
urls=$(echo "$html" | grep -oP 'murl&quot;:&quot;\K[^"&]+' \
  | grep -iE '\.(jpe?g|png|webp)(\?|$)' \
  | sed 's/\\u002F/\//g; s/\\u0026/\&/g' \
  | awk '!seen[$0]++' | head -n 12)
echo "candidates: $(echo "$urls" | grep -c .)"
i=0
for u in $urls; do
  [ "$i" -ge 3 ] && break
  # 尺寸粗滤: 尝试 HEAD 拿 content-length, 跳过 <30KB 与 >8MB
  cl=$(curl -sI -A "$UA" -L "$u" --max-time 20 | grep -i '^content-length' | tail -1 | grep -oP '\d+' || true)
  if [ -n "$cl" ] && [ "${cl:-0}" -lt 30000 ]; then continue; fi
  ext="${u##*.}"; ext=$(echo "$ext" | cut -d'?' -f1 | tr 'A-Z' 'a-z')
  case "$ext" in jpg|jpeg|png|webp) ;; *) continue ;; esac
  i=$((i+1))
  src=$(echo "$u" | sed -E 's|https?://([^/]+).*|\1|' | tr -cd 'a-zA-Z0-9.-' | head -c 24)
  fn="ref${i}_${src}.${ext/jpeg/jpg}"
  code=$(curl -s -A "$UA" -L "$u" -o "/tmp/facimg_${i}.img" --max-time 60 -w "%{http_code}")
  sz=$(stat -c%s "/tmp/facimg_${i}.img" 2>/dev/null || echo 0)
  if [ "$code" = "200" ] && [ "${sz:-0}" -gt 30000 ] && [ "${sz:-0}" -lt 9000000 ]; then
    up=$(curl -s -u "$NS_U:$NS_P" -T "/tmp/facimg_${i}.img" "${NS_BASE}/${DEST}/${fn}" -o /dev/null -w "%{http_code}" --max-time 60)
    echo "img$i $fn ${sz}B up=$up src=$u"
  else
    echo "img$i SKIP code=$code sz=${sz}"
  fi
  rm -f "/tmp/facimg_${i}.img"
done
