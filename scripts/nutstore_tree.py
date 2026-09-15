#!/usr/bin/env python3
"""递归 PROPFIND 坚果云目录，输出树状结构（含大小/时间）。只读侦察。"""
import os
import sys, urllib.parse, xml.etree.ElementTree as ET
import subprocess, json, datetime
def _secret(key, default=""):
    """优先环境变量；否则回落解析 /root/.nutstore.env（600）。"""
    v = os.environ.get(key, "")
    if v:
        return v
    try:
        for _ln in open("/root/.nutstore.env"):
            if _ln.startswith(key + "="):
                return _ln.split("=", 1)[1].strip()
    except Exception:
        pass
    print("[warn] 缺少凭据 %s（见 /root/.nutstore.env）" % key, flush=True)
    return default

BASE = "https://dav.jianguoyun.com/dav"
USER = "drin@vip.qq.com"
PASS = _secret("NUTSTORE_PASS")

def propfind(path, depth="1"):
    url = BASE + urllib.parse.quote(path)
    r = subprocess.run(
        ["curl", "-s", "-u", f"{USER}:{PASS}", "-X", "PROPFIND",
         "-H", f"Depth: {depth}", "--max-time", "120", url],
        capture_output=True, text=True)
    if r.returncode != 0 or not r.stdout.strip():
        return []
    try:
        root = ET.fromstring(r.stdout)
    except ET.ParseError:
        return []
    ns = {"d": "DAV:"}
    out = []
    for resp in root.findall("d:response", ns):
        href = resp.findtext("d:href", default="", namespaces=ns)
        p = urllib.parse.unquote(href)
        p = p[len("/dav"):] if p.startswith("/dav") else p
        if p.rstrip("/") == path.rstrip("/"):
            continue
        rt = resp.find(".//d:resourcetype", ns)
        isdir = rt is not None and rt.find("d:collection", ns) is not None
        size = resp.findtext(".//d:getcontentlength", default="", namespaces=ns)
        mtime = resp.findtext(".//d:getlastmodified", default="", namespaces=ns)
        out.append({"path": p, "dir": isdir, "size": int(size) if size else 0,
                    "mtime": mtime})
    return out

def walk(path, depth=0, maxdepth=6, out=None):
    if out is None:
        out = []
    for e in propfind(path):
        out.append((depth, e))
        if e["dir"] and depth < maxdepth:
            walk(e["path"], depth + 1, maxdepth, out)
    return out

if __name__ == "__main__":
    root = sys.argv[1] if len(sys.argv) > 1 else "/01_CURR_PRJ/2026-16 XING SHUN LI/DESIGN/PPTX"
    md = int(sys.argv[2]) if len(sys.argv) > 2 else 6
    rows = walk(root, maxdepth=md)
    print(f"ROOT: {root}  ({len(rows)} entries)")
    for depth, e in rows:
        ind = "  " * depth
        if e["dir"]:
            print(f"{ind}[D] {e['path'].rstrip('/').split('/')[-1]}/")
        else:
            print(f"{ind}    {e['path'].split('/')[-1]}  |  {e['size']:,}B  |  {e['mtime']}")
    with open("/tmp/nutstore_tree.json", "w") as f:
        json.dump([{"depth": d, **e} for d, e in rows], f, ensure_ascii=False, indent=1)
