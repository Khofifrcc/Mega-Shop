from pydantic import BaseModel

class ProductCreate(BaseModel):
    name: str
    price: int
    description: str
    image: str
    seller_name: str = "MegaShop User"