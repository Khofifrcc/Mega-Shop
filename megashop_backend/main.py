from fastapi import FastAPI

app = FastAPI(title="Mega Shop API")

@app.get("/")
def root():
    return {
        "message": "Mega Shop Backend Running 🚀"
    }

@app.get("/products")
def get_products():
    return [
        {
            "id": 1,
            "name": "Red Dress",
            "price": 250,
            "image": "https://picsum.photos/200",
            "description": "Beautiful red dress"
        },
        {
            "id": 2,
            "name": "Sneakers",
            "price": 400,
            "image": "https://picsum.photos/201",
            "description": "Comfortable sneakers"
        }
    ]

@app.get("/reels")
def get_reels():
    return [
        {
            "id": 1,
            "title": "Fashion Reel",
            "product_id": 1
        }
    ]

@app.get("/cart")
def get_cart():
    return []

@app.post("/cart")
def add_to_cart():
    return {
        "message": "Product added to cart"
    }