from pydantic import BaseModel

class PostCreate(BaseModel):
    user_id: str
    caption: str
    image: str