from pydantic import BaseModel

class ReelCreate(BaseModel):
    user_id: str
    caption: str
    video: str
    product_name: str = ""
    price: int = 0
    image: str = ""
    is_product: bool = False