from pydantic import BaseModel

class PostCreate(BaseModel):
    user_id: str
    caption: str
    image: str
    post_type: str = "regular"
    user_name: str = "User"