from fastapi import APIRouter, HTTPException
from app.schemas.product_schema import ProductCreate

router = APIRouter(prefix="/products", tags=["Products"])

products = [
    {
        "id": 1,
        "name": "Pink Hoodie",
        "price": 300000,
        "description": "Oversized hoodie",
        "image": "https://picsum.photos/500"
    }
]

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
    new_product = {"id": len(products) + 1, **product.dict()}
    products.append(new_product)
    return {"message": "Product created successfully", "data": new_product}

@router.put("/{product_id}")
def update_product(product_id: int, updated_product: ProductCreate):
    for product in products:
        if product["id"] == product_id:
            product.update(updated_product.dict())
            return {"message": "Product updated successfully", "data": product}
    raise HTTPException(status_code=404, detail="Product not found")

@router.delete("/{product_id}")
def delete_product(product_id: int):
    for product in products:
        if product["id"] == product_id:
            products.remove(product)
            return {"message": "Product deleted successfully"}
    raise HTTPException(status_code=404, detail="Product not found")