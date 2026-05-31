from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
import os
from fastapi import UploadFile, File
from fastapi.staticfiles import StaticFiles

from app.routers import (
    product_router,
    post_router,
    reel_router,
    user_router,
)

app = FastAPI(title="Mega Shop API")
os.makedirs("uploads", exist_ok=True)
app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")
@app.post("/upload")
async def upload_file(file: UploadFile = File(...)):
    file_path = f"uploads/{file.filename}"

    with open(file_path, "wb") as buffer:
        buffer.write(await file.read())

    return {
        "url": f"/uploads/{file.filename}"
    }

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")

app.include_router(product_router.router)
app.include_router(post_router.router)
app.include_router(reel_router.router)
app.include_router(user_router.router)

@app.get("/")
def home():
    return {"message": "Mega Shop API Running"}
