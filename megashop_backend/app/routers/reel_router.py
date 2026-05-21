from fastapi import APIRouter, HTTPException
from app.schemas.reel_schema import ReelCreate

router = APIRouter(prefix="/reels", tags=["Reels"])

reels = []

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
    return new_reel