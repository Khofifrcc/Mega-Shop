from fastapi import FastAPI
import os
import shutil
from fastapi.staticfiles import StaticFiles
from uuid import uuid4
from fastapi import APIRouter, File, UploadFile, HTTPException
router = APIRouter(prefix="/upload", tags=["Upload"])
UPLOAD_DIR = "uploads"
from app.routers import (
    product_router,
    post_router,
    reel_router,
    upload_router,
)

@router.post("/image")
def upload_image(file: UploadFile = File(...)):
    # Only allow image files
    if not file.content_type.startswith("image/"):
        raise HTTPException(status_code=400, detail="Only image files are allowed")

    os.makedirs(UPLOAD_DIR, exist_ok=True)

    # Create unique filename
    file_extension = file.filename.split(".")[-1]
    filename = f"{uuid4()}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    # Save file to uploads folder
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return {
        "message": "Image uploaded successfully",
        "image_url": f"http://127.0.0.1:8000/uploads/{filename}"
    }
from fastapi.middleware.cors import CORSMiddleware
from app.routers import (
    product_router,
    post_router,
    reel_router,
   #cart_router,
    #order_router,
    #user_router
)

app = FastAPI(title="Mega Shop API")
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
app.include_router(upload_router.router)
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

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