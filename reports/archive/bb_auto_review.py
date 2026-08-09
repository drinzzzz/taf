#!/usr/bin/env python3
"""BookBaker Auto-Review — AI 批量审查 inbox fragments，确认有效或丢弃。

用法:
    python3 bb_auto_review.py [--batch 10] [--dry-run]

由 ENTH cron 通过 SSH 触发：
    ssh dw python3 /root/bb_auto_review.py

DW 本地 fallback cron 在 ENTH 不可达时自动运行。
"""

import json
import os
import ssl
import sys
import time
import urllib.request
import urllib.error
import urllib.parse
from datetime import datetime

# ── Config ──
API_BASE = "http://127.0.0.1:8700"
DASHSCOPE_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"

# Load DashScope key from hermes .env
def _load_key():
    env_path = os.path.expanduser("~/.hermes/.env")
    if not os.path.exists(env_path):
        return ""
    for line in open(env_path):
        if line.startswith("DASHSCOPE_API_KEY"):
            return line.split("=", 1)[1].strip()
    return ""

DS_KEY = _load_key()

# ── Review prompt ──
SYSTEM_PROMPT = """你是书稿《TA+SPACE 家猫》的内容审查员。下面是从互联网采集的资料片段。
请判断该片段是否对书籍有价值。

判断标准：
- ✅ 保留 (valid)：包含猫/宠物相关的事实、数据、研究、专家观点、趣闻、护理知识、品种信息等
- ❌ 丢弃 (discard)：纯导航菜单、网站页脚、广告、错误信息、完全无关内容

只回复一个词：valid 或 discard。不要解释。"""


def api_get(path, params=None):
    """GET from BookBaker API."""
    url = f"{API_BASE}{path}"
    if params:
        qs = "&".join(f"{k}={v}" for k, v in params.items())
        url += "?" + qs
    req = urllib.request.Request(url)
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode())


def api_post(path, params=None):
    """POST to BookBaker API."""
    url = f"{API_BASE}{path}"
    if params:
        qs = "&".join(f"{k}={urllib.parse.quote(str(v))}" for k, v in params.items())
        url += "?" + qs
    req = urllib.request.Request(url, method="POST")
    with urllib.request.urlopen(req, timeout=15) as resp:
        return json.loads(resp.read().decode())


def llm_review(content):
    """Send fragment content to Qwen for classification."""
    body = json.dumps({
        "model": "qwen-plus",
        "messages": [
            {"role": "system", "content": SYSTEM_PROMPT},
            {"role": "user", "content": content[:1200]}  # truncate to save tokens
        ],
        "max_tokens": 10,
        "temperature": 0,
    }).encode()
    req = urllib.request.Request(DASHSCOPE_URL, data=body)
    req.add_header("Authorization", f"Bearer {DS_KEY}")
    req.add_header("Content-Type", "application/json")
    ctx = ssl.create_default_context()
    with urllib.request.urlopen(req, timeout=30, context=ctx) as resp:
        data = json.loads(resp.read().decode())
    return data["choices"][0]["message"]["content"].strip().lower()


def main(batch_size=10, dry_run=False):
    if not DS_KEY:
        print("[ERROR] DashScope API key not configured")
        sys.exit(1)

    # Fetch inbox fragments
    print(f"[{datetime.now().strftime('%H:%M:%S')}] 拉取 inbox fragments...")
    data = api_get("/api/fragments", {"status": "inbox", "limit": batch_size, "offset": 0})
    fragments = data.get("fragments", [])
    stats = data.get("counts", {})
    print(f"  inbox 总量: {stats.get('inbox', '?')}，本次取到 {len(fragments)} 条")

    if not fragments:
        print("  无待审条目，结束。")
        return

    valid_count = 0
    discard_count = 0
    error_count = 0

    for i, f in enumerate(fragments):
        fid = f["id"]
        content = (f.get("content") or "")[:300]
        source = f.get("source", "?")
        print(f"  [{i+1}/{len(fragments)}] #{fid} {source[:40]}...")

        if dry_run:
            # Mock review for testing
            verdict = "valid" if len(content) > 80 else "discard"
            time.sleep(0.1)
        else:
            try:
                verdict = llm_review(f["content"])
            except Exception as e:
                print(f"    ⚠ LLM 调用失败: {e}")
                error_count += 1
                continue

        new_status = "processed" if verdict == "valid" else "discarded"
        summary = "✅ 保留" if verdict == "valid" else "🗑 丢弃"

        try:
            if not dry_run:
                api_post(f"/api/fragments/{fid}/status", {"status": new_status})
            print(f"    {summary} → {new_status}")
            if verdict == "valid":
                valid_count += 1
            else:
                discard_count += 1
        except Exception as e:
            print(f"    ⚠ 状态更新失败: {e}")
            error_count += 1
            continue

    print(f"\n[完成] 保留 {valid_count} 条，丢弃 {discard_count} 条，出错 {error_count} 条")

    # Refresh stats
    data2 = api_get("/api/fragments", {"status": "inbox", "limit": 1})
    remaining = data2.get("counts", {}).get("inbox", "?")
    print(f"  inbox 剩余: {remaining}")


if __name__ == "__main__":
    import argparse
    parser = argparse.ArgumentParser()
    parser.add_argument("--batch", type=int, default=10)
    parser.add_argument("--dry-run", action="store_true")
    args = parser.parse_args()
    main(batch_size=args.batch, dry_run=args.dry_run)
