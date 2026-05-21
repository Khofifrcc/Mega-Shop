from pydantic import BaseModel

class ReelCreate(BaseModel):
    user_id: str
    caption: str
    video_url: str
    product_id: int