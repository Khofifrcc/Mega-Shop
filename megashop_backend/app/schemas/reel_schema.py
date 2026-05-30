from pydantic import BaseModel
from typing import Optional

class ReelCreate(BaseModel):
    username: str
    user_avatar: str
    product_name: str
    price: float
    original_price: Optional[float] = None
    image_url: str
    like_count: int = 0
    comment_count: int = 0
    is_following: bool = False
    video_url: str