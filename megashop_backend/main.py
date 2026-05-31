from fastapi import FastAPI, UploadFile, File
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from pathlib import Path
import shutil

from app.routers import (
    product_router,
    post_router,
    reel_router,
)

app = FastAPI(title="Mega Shop API")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

UPLOAD_DIR = Path("uploads")
UPLOAD_DIR.mkdir(exist_ok=True)

app.mount("/uploads", StaticFiles(directory="uploads"), name="uploads")


@app.post("/upload")
def upload_file(file: UploadFile = File(...)):
    file_path = UPLOAD_DIR / file.filename

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return {
        "filename": file.filename,
        "url": f"http://127.0.0.1:8000/uploads/{file.filename}",
    }


app.include_router(product_router.router)
app.include_router(post_router.router)
app.include_router(reel_router.router)


@app.get("/")
def root():
    return {"message": "Mega Shop Backend Running 🚀"}