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
