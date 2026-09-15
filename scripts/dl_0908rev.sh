#!/usr/bin/env bash
# 下载 0908 V1.1 REV 两件套作为基线（只读侦察，不动云端）
set -u
set -a; . /root/.nutstore.env 2>/dev/null; set +a   # 凭据取自 600 文件
BASE="https://dav.jianguoyun.com/dav"
AUTH="$NUTSTORE_USER:$NUTSTORE_PASS"
DEST="/data/disk1/wwwroot/taf/work_20260904/dl_user_0908rev"
mkdir -p "$DEST"
DL="$BASE/01_CURR_PRJ/2026-16%20XING%20SHUN%20LI/DESIGN/PPTX/20260908%20XING_SHUN_LI%20%20V1.1%20REV"
for f in "20260908 XING_SHUN_LI - 01. PLANNING V1.1 REV.pptx" "20260908 XING_SHUN_LI - 02. DRAWINGS V1.1 REV.pptx"; do
  enc=$(python3 -c "import urllib.parse,sys;print(urllib.parse.quote(sys.argv[1]))" "$f")
  echo "--- downloading: $f"
  curl -s -u "$AUTH" -o "$DEST/$f" "$DL/$enc" --max-time 3600 -w "HTTP %{http_code} size=%{size_download} time=%{time_total}s\n"
  ls -l "$DEST/$f" 2>/dev/null
done
echo "=== md5 ==="
md5sum "$DEST"/*.pptx
