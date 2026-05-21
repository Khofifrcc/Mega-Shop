from fastapi import APIRouter, HTTPException
from app.schemas.product_schema import ProductCreate

router = APIRouter(prefix="/products", tags=["Products"])

products = []

@router.get("/")
def get_products():
    return products

@router.get("/{product_id}")
def get_product(product_id: int):
    for product in products:
        if product["id"] == product_id:
            return product
    raise HTTPException(status_code=404, detail="Product not found")

@router.post("/")
def create_product(product: ProductCreate):
    new_product = {
        "id": len(products) + 1,
        **product.dict()
    }
    products.append(new_product)
    return new_product