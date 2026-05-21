from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/reels", tags=["Reels"])

reels = [
    {
        "id": 1,
        "user_id": "user_1",
        "caption": "Try this product!",
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
def create_reel(reel: dict):
    new_reel = {
        "id": len(reels) + 1,
        **reel
    }
    reels.append(new_reel)
    return new_reel