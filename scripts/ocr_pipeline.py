#!/usr/bin/env python3
"""
PFA 展位 OCR 管线 v2 — 分条扫描 + 逐条 Qwen VL 识别
策略: 将展厅图逆时针旋转90°后, 切分为4-8条水平带, 每条独立OCR, 去重入库
可续传: 每个展厅完成后保存 checkpoint, 中断后重新运行自动跳过已完成展厅

用法:
  python3 scripts/ocr_pipeline.py                    # 全量续传
  python3 scripts/ocr_pipeline.py --hall W1           # 单展厅
  python3 scripts/ocr_pipeline.py --hall W1 --force   # 强制重跑
  python3 scripts/ocr_pipeline.py --status            # 查看进度
  python3 scripts/ocr_pipeline.py --batch N           # 先跑 N 个展厅
"""

import os, sys, json, time, base64, re, cv2, argparse
from pathlib import Path
from difflib import SequenceMatcher

import requests
import psycopg2

# ── Paths ──────────────────────────────────────────────
BASE_DIR   = Path("/data/disk1/wwwroot/taf")
IMAGE_DIR  = BASE_DIR / "frontend/pfa_images"
CKPT_FILE  = BASE_DIR / "scripts/ocr_checkpoint.json"

# ── API Config ─────────────────────────────────────────
DS_KEY = None
with open("/root/.hermes/.env") as f:
    for line in f:
        if line.startswith("DASHSCOPE_API_KEY="):
            DS_KEY = line.strip().split("=", 1)[1]
            break

API_URL = "https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions"
HEADERS = {"Authorization": f"Bearer {DS_KEY}", "Content-Type": "application/json"}

# ── DB ─────────────────────────────────────────────────
def get_db():
    return psycopg2.connect(host="127.0.0.1", port=5432, dbname="taf", user="postgres", password="R@De432!")


# ── Qwen VL call ──────────────────────────────────────
def qwen_ocr_strip(img_bgr, hall_code, strip_idx, total_strips):
    """Send a horizontal strip image to Qwen VL, return raw text output."""
    try:
        _, buf = cv2.imencode('.jpg', img_bgr, [cv2.IMWRITE_JPEG_QUALITY, 55])
        img_b64 = base64.b64encode(buf).decode()
    except Exception as e:
        return None, f"encode_error: {e}"

    prompt = f"""Pet Fair Asia 2026 floor plan, Hall {hall_code}, strip {strip_idx+1}/{total_strips}.

Extract EVERY booth from this image strip. Output EXACTLY one per line:
booth_number | company_name

CRITICAL RULES:
- Only read booths ACTUALLY VISIBLE with text labels
- Do NOT invent sequential booth numbers
- If you cannot read clearly, SKIP it
- Each company should appear AT MOST ONCE
- No extra text, no explanations, no markdown"""

    payload = {
        "model": "qwen-vl-max",
        "messages": [{
            "role": "user",
            "content": [
                {"type": "text", "text": prompt},
                {"type": "image_url", "image_url": {"url": f"data:image/jpeg;base64,{img_b64}"}}
            ]
        }],
        "max_tokens": 2048,
        "temperature": 0.0
    }

    for attempt in range(3):
        try:
            resp = requests.post(API_URL, headers=HEADERS, json=payload, timeout=120)
            if resp.status_code == 429:
                time.sleep(5 * (attempt + 1))
                continue
            if resp.status_code != 200:
                time.sleep(3)
                continue
            data = resp.json()
            if "choices" not in data:
                time.sleep(3)
                continue
            text = data["choices"][0]["message"]["content"].strip()
            return text, None
        except Exception as e:
            time.sleep(3)
            continue
    return None, "api_fail_3x"


# ── Parse OCR output ──────────────────────────────────
def parse_booths(text, hall_code):
    """Parse Qwen VL output into list of (booth_number, company_name)."""
    results = []
    seen = set()
    for line in text.split('\n'):
        line = line.strip()
        if not line or len(line) < 6:
            continue
        if any(kw in line.lower() for kw in ['hall', 'pet fair', 'exhibitor', 'booth number',
                                               'critical rules', 'extract every', 'output exactly']):
            continue

        parts = None
        if ' | ' in line:
            parts = line.split(' | ', 1)
        elif '|' in line:
            parts = line.split('|', 1)
        else:
            # Try: booth_number followed by 2+ spaces then name
            m = re.match(r'^([A-Za-z]?\d+[A-Za-z]?\d*)\s{2,}(.+)', line)
            if m:
                parts = [m.group(1), m.group(2)]
            else:
                # Try: booth_number single space name (less reliable)
                m = re.match(r'^([A-Za-z]?\d+[A-Za-z]?\d*)\s+(.+)', line)
                if m:
                    parts = [m.group(1), m.group(2)]

        if not parts:
            continue

        bn = re.sub(r'[^A-Za-z0-9]', '', parts[0].strip().upper())
        cn = parts[1].strip()[:390]

        if len(bn) < 2 or not cn:
            continue
        # Skip obvious noise
        if all(c.isdigit() for c in cn[:3]):
            continue
        # Skip duplicates within this hall
        if bn in seen:
            continue
        seen.add(bn)
        results.append((bn, cn))
    return results


# ── Exhibitor fuzzy match ──────────────────────────────
def load_exhibitors():
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id, name FROM pfa_exhibitors")
    rows = cur.fetchall()
    conn.close()
    names = [r[1] for r in rows if r[1]]
    ids = [str(r[0]) for r in rows if r[1]]
    return names, ids


def fuzzy_match(company_name, exh_names, exh_ids, threshold=0.80):
    cn = company_name.strip().lower()
    # Exact
    for i, name in enumerate(exh_names):
        if name.strip().lower() == cn:
            return exh_ids[i]
    # Substring
    for i, name in enumerate(exh_names):
        nl = name.strip().lower()
        if cn in nl or nl in cn:
            if len(min(cn, nl, key=len)) / max(len(cn), len(nl), 1) > 0.5:
                return exh_ids[i]
    # Fuzzy
    best_score, best_id = 0, None
    for i, name in enumerate(exh_names):
        s = SequenceMatcher(None, cn, name.strip().lower()).ratio()
        if s > best_score:
            best_score = s
            best_id = exh_ids[i]
    return best_id if best_score >= threshold else None


# ── Checkpoint ─────────────────────────────────────────
def load_checkpoint():
    if CKPT_FILE.exists():
        with open(CKPT_FILE) as f:
            return json.load(f)
    return {"done": [], "strips_processed": 0, "booths_found": 0, "hall_details": {}}


def save_checkpoint(ckpt):
    with open(CKPT_FILE, 'w') as f:
        json.dump(ckpt, f, indent=2, ensure_ascii=False)


# ── Process one hall ───────────────────────────────────
def process_hall(hall_code, exh_names, exh_ids, ckpt, num_strips=None):
    img_path = IMAGE_DIR / f"{hall_code}.jpg"
    if not img_path.exists():
        print(f"  ✗ {hall_code}: image not found")
        ckpt["done"].append(hall_code)
        save_checkpoint(ckpt)
        return

    img = cv2.imread(str(img_path))
    if img is None:
        print(f"  ✗ {hall_code}: failed to read image")
        ckpt["done"].append(hall_code)
        save_checkpoint(ckpt)
        return

    # Rotate CCW so text is horizontal
    img = cv2.rotate(img, cv2.ROTATE_90_COUNTERCLOCKWISE)
    h, w = img.shape[:2]

    # Determine number of strips
    if num_strips is None:
        num_strips = max(4, min(8, h // 350))
    strip_h = h // num_strips
    overlap = strip_h // 6  # ~16% overlap

    print(f"  {hall_code}: {w}x{h} → {num_strips} strips × ~{strip_h}px (+{overlap} overlap)")

    # Get DB IDs
    conn = get_db()
    cur = conn.cursor()
    cur.execute("SELECT id FROM pfa_halls WHERE code = %s", (hall_code,))
    hall_row = cur.fetchone()
    if not hall_row:
        conn.close()
        print(f"  ✗ {hall_code}: hall not found in DB")
        return
    hall_id = str(hall_row[0])
    cur.execute("SELECT id FROM pfa_expos LIMIT 1")
    expo_row = cur.fetchone()
    expo_id = str(expo_row[0]) if expo_row else None
    conn.close()

    all_booths = {}  # {booth_number: (company_name, exhibitor_id, strip_idx)}

    for si in range(num_strips):
        y0 = max(0, si * strip_h - (overlap if si > 0 else 0))
        y1 = min(h, (si + 1) * strip_h + overlap)
        strip_img = img[y0:y1, 0:w]

        print(f"    strip {si+1}/{num_strips} [{y0}:{y1}] ...", end=" ", flush=True)
        t0 = time.time()
        text, err = qwen_ocr_strip(strip_img, hall_code, si, num_strips)
        elapsed = time.time() - t0

        if err:
            print(f"✗ {err} ({elapsed:.1f}s)")
            continue

        booths = parse_booths(text, hall_code)
        new_count = 0
        for bn, cn in booths:
            if bn not in all_booths:
                eid = fuzzy_match(cn, exh_names, exh_ids)
                all_booths[bn] = (cn, eid, si)
                new_count += 1

        print(f"✓ {len(booths)} raw, {new_count} new ({elapsed:.1f}s)")
        ckpt.setdefault("strips_processed", 0)
        ckpt["strips_processed"] += 1
        save_checkpoint(ckpt)

        # Rate limit
        if si < num_strips - 1:
            time.sleep(1.5)

    # Insert into DB
    conn = get_db()
    cur = conn.cursor()
    inserted = 0
    for bn, (cn, eid, si) in all_booths.items():
        # Estimate position from strip index
        pos_x = int(w * 0.5)  # center
        pos_y = int((si + 0.5) * h / num_strips)
        try:
            cur.execute(
                """INSERT INTO pfa_booths (expo_id, hall_id, exhibitor_id, booth_number, pos_x, pos_y, is_verified, raw_company_name)
                   VALUES (%s,%s,%s,%s,%s,%s,%s,%s)
                   ON CONFLICT (expo_id, hall_id, booth_number) DO UPDATE
                   SET exhibitor_id = EXCLUDED.exhibitor_id, pos_y = EXCLUDED.pos_y, raw_company_name = EXCLUDED.raw_company_name""",
                (expo_id, hall_id, eid, bn, pos_x, pos_y, eid is not None, cn)
            )
            inserted += 1
        except Exception as e:
            pass

    conn.commit()
    conn.close()

    matched = sum(1 for _, eid, _ in all_booths.values() if eid)
    ckpt.setdefault("done", [])
    ckpt["done"].append(hall_code)
    ckpt.setdefault("booths_found", 0)
    ckpt["booths_found"] += len(all_booths)
    ckpt.setdefault("hall_details", {})
    ckpt["hall_details"][hall_code] = {"booths": len(all_booths), "matched": matched}
    save_checkpoint(ckpt)

    print(f"  ✓ {hall_code}: {len(all_booths)} unique booths ({matched} matched to exhibitors)")


# ── Hall sort order ────────────────────────────────────
def hall_sort_key(code):
    """Natural sort: W1 before W10, E1 before E2"""
    m = re.match(r'^([A-Z]+)(\d+)$', code)
    if m:
        return (m.group(1), int(m.group(2)))
    return (code, 0)


# ── Main ───────────────────────────────────────────────
def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--hall", type=str)
    parser.add_argument("--force", action="store_true")
    parser.add_argument("--status", action="store_true")
    parser.add_argument("--batch", type=int, default=0, help="Process only first N pending halls")
    args = parser.parse_args()

    ckpt = load_checkpoint()

    # Valid halls = those with images
    valid_halls = sorted(
        [p.stem for p in IMAGE_DIR.glob("*.jpg") if p.stem != "index_plan"],
        key=hall_sort_key
    )

    if args.status:
        print("=== PFA OCR Progress ===")
        done = ckpt.get("done", [])
        print(f"Done: {len(done)}/{len(valid_halls)} halls")
        if ckpt.get("hall_details"):
            for h, d in sorted(ckpt["hall_details"].items(), key=lambda x: hall_sort_key(x[0])):
                print(f"  ✓ {h}: {d['booths']} booths ({d['matched']} matched)")
        else:
            for h in done:
                conn = get_db(); cur = conn.cursor()
                cur.execute("SELECT COUNT(*) FROM pfa_booths b JOIN pfa_halls h2 ON b.hall_id=h2.id WHERE h2.code=%s", (h,))
                n = cur.fetchone()[0]; conn.close()
                print(f"  ✓ {h}: {n} booths")
        pending = [h for h in valid_halls if h not in done]
        print(f"Pending ({len(pending)}): {', '.join(pending[:10])}{'...' if len(pending)>10 else ''}")
        print(f"Strips processed: {ckpt.get('strips_processed', 0)}")
        print(f"Total booths found: {ckpt.get('booths_found', 0)}")
        return

    print("Loading exhibitors...")
    exh_names, exh_ids = load_exhibitors()
    print(f"  {len(exh_names)} exhibitors loaded")

    done = set(ckpt.get("done", []))
    halls_to_do = [h for h in valid_halls if h not in done]

    if args.hall:
        if args.force and args.hall in done:
            done.discard(args.hall)
            ckpt["done"] = list(done)
            save_checkpoint(ckpt)
        halls_to_do = [args.hall]

    if args.batch > 0:
        halls_to_do = halls_to_do[:args.batch]

    if not halls_to_do:
        print("All halls done! ✓")
        return

    print(f"\nProcessing {len(halls_to_do)} halls: {', '.join(halls_to_do)}")
    print(f"Checkpoint: {CKPT_FILE}\n")

    for idx, hall_code in enumerate(halls_to_do):
        print(f"[{idx+1}/{len(halls_to_do)}] {hall_code}")
        try:
            process_hall(hall_code, exh_names, exh_ids, ckpt)
        except KeyboardInterrupt:
            print(f"\n  ⚠ Interrupted at {hall_code}. Checkpoint saved.")
            print(f"  Resume: python3 scripts/ocr_pipeline.py")
            return
        except Exception as e:
            print(f"  ✗ {hall_code}: {type(e).__name__}: {e}")
            import traceback
            traceback.print_exc()
            save_checkpoint(ckpt)
        print()

    # Summary
    done = ckpt.get("done", [])
    print(f"Batch complete. {len(done)}/{len(valid_halls)} halls done.")
    print(f"Total booths: {ckpt.get('booths_found', 0)}")
    print(f"Checkpoint: {CKPT_FILE}")


if __name__ == "__main__":
    main()
