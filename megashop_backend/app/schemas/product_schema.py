from pydantic import BaseModel

class ProductCreate(BaseModel):
    user_id: str
    name: str
    price: int
    description: str
    image: str