from fastapi import APIRouter, HTTPException
from app.schemas.reel_schema import ReelCreate
from app.database import get_connection

router = APIRouter(prefix="/reels", tags=["Reels"])

@router.get("/")
def get_reels():
    conn = get_connection()
    rows = conn.execute("SELECT * FROM reels ORDER BY id DESC").fetchall()
    conn.close()
    return [dict(row) for row in rows]

@router.get("/user/{user_id}")
def get_reels_by_user(user_id: str):
    conn = get_connection()
    rows = conn.execute(
        "SELECT * FROM reels WHERE user_id = ? ORDER BY id DESC",
        (user_id,),
    ).fetchall()
    conn.close()
    return [dict(row) for row in rows]

@router.post("/")
@router.post("/")
def create_reel(reel: ReelCreate):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute(
        """
        INSERT INTO reels (user_id, caption, video, product_name, price, image)
        VALUES (?, ?, ?, ?, ?, ?)
        """,
        (
            reel.user_id,
            reel.caption,
            reel.video,
            reel.product_name,
            reel.price,
            reel.image,
        ),
    )
    conn.commit()
    new_id = cur.lastrowid
    conn.close()

    return {
        "message": "Reel created successfully",
        "data": {"id": new_id, **reel.dict()},
    }

@router.delete("/{reel_id}")
def delete_reel(reel_id: int):
    conn = get_connection()
    cur = conn.cursor()
    cur.execute("DELETE FROM reels WHERE id = ?", (reel_id,))
    conn.commit()
    deleted = cur.rowcount
    conn.close()

    if deleted == 0:
        raise HTTPException(status_code=404, detail="Reel not found")

    return {"message": "Reel deleted successfully"}