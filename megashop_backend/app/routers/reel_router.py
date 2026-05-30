from fastapi import APIRouter, HTTPException
from app.schemas.reel_schema import ReelCreate

router = APIRouter(prefix="/reels", tags=["Reels"])

reels = [
    {
        "id": 1,
        "username": "fashionista_store",
        "user_avatar": "https://picsum.photos/100",
        "product_name": "Summer Floral Dress",
        "price": 89.0,
        "original_price": 120.0,
        "image_url": "https://picsum.photos/600/900",
        "like_count": 24500,
        "comment_count": 892,
        "is_following": False
    }
]

@router.get("/")
def get_reels():
    return reels

@router.get("/{reel_id}")
def get_reel(reel_id: int):
    for reel in reels:
        if reel["id"] == reel_id:
            return reel
    raise HTTPException(status_code=404, detail="Reel not found")

@router.post("/")
def create_reel(reel: ReelCreate):
    new_reel = {
        "id": len(reels) + 1,
        **reel.dict()
    }
    reels.append(new_reel)
    return {
        "message": "Reel created successfully",
        "data": new_reel
    }

@router.put("/{reel_id}")
def update_reel(reel_id: int, updated_reel: ReelCreate):
    for reel in reels:
        if reel["id"] == reel_id:
            reel.update(updated_reel.dict())
            return {
                "message": "Reel updated successfully",
                "data": reel
            }
    raise HTTPException(status_code=404, detail="Reel not found")

@router.delete("/{reel_id}")
def delete_reel(reel_id: int):
    for reel in reels:
        if reel["id"] == reel_id:
            reels.remove(reel)
            return {"message": "Reel deleted successfully"}
    raise HTTPException(status_code=404, detail="Reel not found")