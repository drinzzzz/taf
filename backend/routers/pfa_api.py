"""PFA 亚宠展展位地图 API"""
from fastapi import APIRouter, Query, HTTPException
from fastapi.responses import FileResponse
import psycopg2, json, os

router = APIRouter(prefix="/api/pfa", tags=["PFA"])

def get_db():
    return psycopg2.connect(host="127.0.0.1", port=5432, dbname="taf", user="postgres", password="R@De432!")

@router.get("/halls")
def list_halls():
    conn = get_db(); cur = conn.cursor()
    cur.execute("SELECT code, name, name_en, booth_count FROM pfa_halls WHERE booth_count > 0 ORDER BY substring(code,'^[A-Z]+'), substring(code,'\d+$')::int")
    halls = [{"code": r[0], "name": r[1], "name_en": r[2], "booth_count": r[3]} for r in cur.fetchall()]
    conn.close()
    return halls

@router.get("/halls/{code}/image")
def hall_image(code: str):
    path = f"/data/disk1/wwwroot/taf/frontend/pfa_images/{code}.jpg"
    if os.path.exists(path):
        return FileResponse(path, media_type="image/jpeg")
    raise HTTPException(404, "Image not found")

@router.get("/halls/{code}/booths")
def hall_booths(code: str):
    conn = get_db(); cur = conn.cursor()
    cur.execute("""
        SELECT b.id, b.booth_number, e.name as exhibitor, b.pos_x, b.pos_y,
               bv.id as visit_id, bv.rating, bv.notes, bv.is_planned,
               bv.social_ready, array_to_string(bv.photos, ',') as photos
        FROM pfa_booths b
        JOIN pfa_halls h ON b.hall_id = h.id
        JOIN pfa_exhibitors e ON b.exhibitor_id = e.id
        LEFT JOIN pfa_booth_visits bv ON bv.booth_id = b.id
        WHERE h.code = %s
        ORDER BY b.pos_y, b.pos_x
    """, (code,))
    booths = []
    for r in cur.fetchall():
        booths.append({
            "id": str(r[0]), "booth_number": r[1], "exhibitor": r[2],
            "x": r[3] or 0, "y": r[4] or 0,
            "visit": {
                "id": str(r[5]) if r[5] else None,
                "rating": r[6], "notes": r[7],
                "is_planned": r[8], "social_ready": r[9],
                "photos": r[10].split(',') if r[10] else []
            } if r[5] else None
        })
    conn.close()
    return booths

@router.post("/booths/{booth_id}/visit")
def save_visit(booth_id: str, data: dict):
    conn = get_db(); cur = conn.cursor()
    cur.execute("SELECT id FROM pfa_booth_visits WHERE booth_id = %s", (booth_id,))
    existing = cur.fetchone()
    
    photos = "{" + ",".join(data.get("photos", [])) + "}" if data.get("photos") else None
    
    if existing:
        cur.execute("""
            UPDATE pfa_booth_visits SET rating=%s, notes=%s, is_planned=%s, social_ready=%s, photos=%s
            WHERE booth_id=%s
        """, (data.get("rating"), data.get("notes"), data.get("is_planned"),
              data.get("social_ready"), photos, booth_id))
    else:
        cur.execute("""
            INSERT INTO pfa_booth_visits (booth_id, rating, notes, is_planned, social_ready, photos)
            VALUES (%s,%s,%s,%s,%s,%s)
        """, (booth_id, data.get("rating"), data.get("notes"),
              data.get("is_planned", True), data.get("social_ready", False), photos))
    conn.commit(); conn.close()
    return {"ok": True}

@router.get("/grid/{code}")
def hall_grid(code: str):
    """Return grid overlay data for frontend rendering"""
    path = f"/tmp/pfa_all_grids.json"
    if os.path.exists(path):
        with open(path) as f:
            grids = json.load(f)
        if code in grids:
            return grids[code]
    return {"h": [], "v": []}


# ── Phase 4: Enhanced APIs ──────────────────────────────

@router.get("/search")
def search_booths(q: str = Query("", description="Search booth number or exhibitor name"),
                   hall: str = Query(None), category: str = Query(None),
                   planned: bool = Query(None), limit: int = Query(100)):
    """Unified search across booths, exhibitors, halls."""
    conn = get_db(); cur = conn.cursor()
    conditions = ["1=1"]
    params = []
    if q:
        conditions.append("(b.booth_number ILIKE %s OR e.name ILIKE %s OR e.name_en ILIKE %s)")
        like = f"%{q}%"
        params.extend([like, like, like])
    if hall:
        conditions.append("h.code = %s")
        params.append(hall)
    if category:
        conditions.append("(e.category = %s OR e.sub_category = %s)")
        params.extend([category, category])
    if planned is not None:
        conditions.append("bv.is_planned = %s")
        params.append(planned)

    query = f"""
        SELECT b.id, b.booth_number, e.name as exhibitor, e.category, e.sub_category,
               h.code as hall_code, h.name as hall_name,
               b.pos_x, b.pos_y,
               bv.id as visit_id, bv.rating, bv.notes, bv.is_planned, bv.social_ready
        FROM pfa_booths b
        JOIN pfa_halls h ON b.hall_id = h.id
        LEFT JOIN pfa_exhibitors e ON b.exhibitor_id = e.id
        LEFT JOIN pfa_booth_visits bv ON bv.booth_id = b.id
        WHERE {' AND '.join(conditions)}
        ORDER BY b.booth_number
        LIMIT %s
    """
    params.append(limit)
    cur.execute(query, params)
    results = []
    for r in cur.fetchall():
        results.append({
            "id": str(r[0]), "booth_number": r[1], "exhibitor": r[2],
            "category": r[3], "sub_category": r[4],
            "hall_code": r[5], "hall_name": r[6],
            "x": r[7] or 0, "y": r[8] or 0,
            "visit": {
                "id": str(r[9]) if r[9] else None,
                "rating": r[10], "notes": r[11],
                "is_planned": r[12], "social_ready": r[13]
            } if r[9] else None
        })
    conn.close()
    return results


@router.get("/plans")
def list_plans():
    """Get all visit plans."""
    conn = get_db(); cur = conn.cursor()
    cur.execute("""
        SELECT vp.id, vp.plan_name, vp.booth_sequence,
               array_length(vp.booth_sequence, 1) as booth_count,
               vp.created_at
        FROM pfa_visit_plans vp
        ORDER BY vp.created_at DESC
    """)
    plans = []
    for r in cur.fetchall():
        plans.append({
            "id": str(r[0]), "name": r[1],
            "booth_ids": list(r[2]) if r[2] else [],
            "booth_count": r[3] or 0,
            "created_at": str(r[4]) if r[4] else None
        })
    conn.close()
    return plans


@router.post("/plans")
def create_plan(data: dict):
    """Create or update a visit plan."""
    conn = get_db(); cur = conn.cursor()
    plan_id = data.get("id")
    name = data.get("name", "未命名计划")
    booth_ids = data.get("booth_ids", [])

    if plan_id:
        cur.execute(
            "UPDATE pfa_visit_plans SET plan_name=%s, booth_sequence=%s WHERE id=%s RETURNING id",
            (name, booth_ids, plan_id)
        )
    else:
        cur.execute("SELECT id FROM pfa_expos LIMIT 1")
        expo_id = cur.fetchone()[0]
        cur.execute(
            "INSERT INTO pfa_visit_plans (expo_id, plan_name, booth_sequence) VALUES (%s, %s, %s) RETURNING id",
            (expo_id, name, booth_ids)
        )
    new_id = cur.fetchone()[0]
    conn.commit(); conn.close()
    return {"id": str(new_id), "ok": True}


@router.delete("/plans/{plan_id}")
def delete_plan(plan_id: str):
    conn = get_db(); cur = conn.cursor()
    cur.execute("DELETE FROM pfa_visit_plans WHERE id = %s", (plan_id,))
    conn.commit(); conn.close()
    return {"ok": True}


@router.get("/stats")
def get_stats():
    """Statistics dashboard."""
    conn = get_db(); cur = conn.cursor()
    cur.execute("SELECT COUNT(*) FROM pfa_booths")
    total_booths = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM pfa_exhibitors")
    total_exhibitors = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM pfa_booths WHERE exhibitor_id IS NOT NULL")
    matched = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM pfa_booth_visits WHERE is_planned = true")
    planned = cur.fetchone()[0]
    cur.execute("SELECT COUNT(*) FROM pfa_booth_visits WHERE rating IS NOT NULL")
    visited = cur.fetchone()[0]

    # Per-hall stats
    cur.execute("""
        SELECT h.code, h.name, COUNT(b.id), COUNT(b.exhibitor_id)
        FROM pfa_halls h
        LEFT JOIN pfa_booths b ON b.hall_id = h.id
        WHERE h.booth_count > 0
        GROUP BY h.code, h.name
        ORDER BY substring(h.code,'^[A-Z]+'), substring(h.code,'\\d+$')::int
    """)
    halls = [{"code": r[0], "name": r[1], "booths": r[2], "matched": r[3]} for r in cur.fetchall()]

    # Category distribution
    cur.execute("""
        SELECT COALESCE(e.category, '未分类'), COUNT(DISTINCT b.id)
        FROM pfa_booths b
        LEFT JOIN pfa_exhibitors e ON b.exhibitor_id = e.id
        GROUP BY e.category ORDER BY COUNT(DISTINCT b.id) DESC
    """)
    categories = [{"name": r[0], "count": r[1]} for r in cur.fetchall()]

    conn.close()
    return {
        "total_booths": total_booths, "total_exhibitors": total_exhibitors,
        "matched": matched, "match_rate": round(100.0 * matched / total_booths, 1) if total_booths else 0,
        "planned": planned, "visited": visited,
        "halls": halls, "categories": categories
    }


@router.get("/exhibitors/{exhibitor_id}")
def exhibitor_detail(exhibitor_id: str):
    """Get exhibitor with all their booths."""
    conn = get_db(); cur = conn.cursor()
    cur.execute("""
        SELECT e.id, e.name, e.name_en, e.brand, e.category, e.sub_category, e.country
        FROM pfa_exhibitors e WHERE e.id = %s
    """, (exhibitor_id,))
    row = cur.fetchone()
    if not row:
        conn.close()
        raise HTTPException(404, "Exhibitor not found")

    exhibitor = {
        "id": str(row[0]), "name": row[1], "name_en": row[2],
        "brand": row[3], "category": row[4], "sub_category": row[5], "country": row[6]
    }

    cur.execute("""
        SELECT b.id, b.booth_number, h.code as hall_code, h.name as hall_name
        FROM pfa_booths b
        JOIN pfa_halls h ON b.hall_id = h.id
        WHERE b.exhibitor_id = %s ORDER BY h.code, b.booth_number
    """, (exhibitor_id,))
    booths = [{"id": str(r[0]), "booth_number": r[1], "hall_code": r[2], "hall_name": r[3]}
              for r in cur.fetchall()]

    conn.close()
    exhibitor["booths"] = booths
    return exhibitor
