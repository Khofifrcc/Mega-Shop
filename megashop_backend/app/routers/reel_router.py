from fastapi import APIRouter, HTTPException
from app.schemas.reel_schema import ReelCreate

router = APIRouter(prefix="/reels", tags=["Reels"])

reels = [
    {
        "id": 1,
        "user_id": "user_1",
        "caption": "Check this hoodie!",
        "video_url": "https://example.com/video.mp4",
        "product_id": 1
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

            return {
                "message": "Reel deleted successfully"
            }

    raise HTTPException(status_code=404, detail="Reel not found")