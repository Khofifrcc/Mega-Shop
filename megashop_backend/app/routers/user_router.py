from fastapi import APIRouter
from app.schemas.user_schema import UserCreate, UserUpdate

router = APIRouter(
    prefix="/users",
    tags=["Users"]
)

fake_db = []

@router.post("/")
def create_user(user: UserCreate):

    for existing_user in fake_db:
        if existing_user["email"] == user.email:
            return {
                "error": "Email already registered"
            }

    fake_db.append(user.dict())

    return {
        "message": "User created successfully",
        "data": user
    }

@router.get("/{firebase_uid}")
def get_user(firebase_uid: str):

    for user in fake_db:
        if user["firebase_uid"] == firebase_uid:
            return user

    return {
        "error": "User not found"
    }

@router.put("/{firebase_uid}")
def update_user(firebase_uid: str, updated_user: UserUpdate):

    for user in fake_db:

        if user["firebase_uid"] == firebase_uid:

            user["username"] = updated_user.username
            user["bio"] = updated_user.bio
            user["profile_photo"] = updated_user.profile_photo

            return {
                "message": "User updated successfully",
                "data": user
            }

    return {
        "error": "User not found"
    }