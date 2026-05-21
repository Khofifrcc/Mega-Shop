from fastapi import APIRouter, HTTPException

router = APIRouter(prefix="/products", tags=["Products"])

products = [
    {
        "id": 1,
        "name": "Pink Hoodie",
        "price": 250000,
        "description": "Comfy hoodie for daily outfit",
        "image": "https://picsum.photos/200"
    },
    {
        "id": 2,
        "name": "White Sneakers",
        "price": 450000,
        "description": "Casual sneakers",
        "image": "https://picsum.photos/201"
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
def create_product(product: dict):
    new_product = {
        "id": len(products) + 1,
        **product
    }
    products.append(new_product)
    return new_product