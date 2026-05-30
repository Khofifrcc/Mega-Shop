import os
import shutil
from uuid import uuid4

from fastapi import APIRouter, File, UploadFile, HTTPException

router = APIRouter(prefix="/upload", tags=["Upload"])

UPLOAD_DIR = "uploads"


@router.post("/image")
def upload_image(file: UploadFile = File(...)):
    os.makedirs(UPLOAD_DIR, exist_ok=True)

    allowed_extensions = ["jpg", "jpeg", "png", "webp"]
    file_extension = file.filename.split(".")[-1].lower()

    if file_extension not in allowed_extensions:
        raise HTTPException(
            status_code=400,
            detail="Only image files are allowed"
        )

    filename = f"{uuid4()}.{file_extension}"
    file_path = os.path.join(UPLOAD_DIR, filename)

    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    return {
        "message": "Image uploaded successfully",
        "image_url": f"http://127.0.0.1:8000/uploads/{filename}"
    }