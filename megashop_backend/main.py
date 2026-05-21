from fastapi import FastAPI
from app.routers import (
    product_router,
    post_router,
    reel_router,
   # cart_router,
    #order_router,
    #user_router
)

app = FastAPI(title="Mega Shop API")

app.include_router(product_router.router)
app.include_router(post_router.router)
app.include_router(reel_router.router)
#app.include_router(cart_router.router)
#app.include_router(order_router.router)
#app.include_router(user_router.router)

@app.get("/")
def root():
    return {
        "message": "Mega Shop Backend Running 🚀"
    }