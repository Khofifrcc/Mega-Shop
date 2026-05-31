from pydantic import BaseModel
from typing import Optional

class ProductCreate(BaseModel):
    user_id: str
    name: str
    price: float
    description: Optional[str] = ""
    image: Optional[str] = ""