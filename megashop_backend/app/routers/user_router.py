from fastapi import APIRouter
from app.schemas.user_schema import UserCreate, UserUpdate
from app.database import get_connection

router = APIRouter(
    prefix="/users",
    tags=["Users"]
)

@router.post("/")
def create_user(user: UserCreate):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT * FROM users WHERE firebase_uid = ? OR email = ?",
        (user.firebase_uid, user.email)
    )
    existing_user = cursor.fetchone()

    if existing_user:
        conn.close()
        return {"message": "User already exists"}

    cursor.execute(
        """
        INSERT INTO users (firebase_uid, email, username, bio, profile_photo)
        VALUES (?, ?, ?, ?, ?)
        """,
        (
            user.firebase_uid,
            user.email,
            user.username,
            user.bio,
            user.profile_photo
        )
    )

    conn.commit()
    conn.close()

    return {
        "message": "User created successfully",
        "data": user
    }


@router.get("/{firebase_uid}")
def get_user(firebase_uid: str):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT * FROM users WHERE firebase_uid = ?",
        (firebase_uid,)
    )
    user = cursor.fetchone()
    conn.close()

    if not user:
        return {
            "firebase_uid": firebase_uid,
            "username": "",
            "email": "",
            "bio": "",
            "profile_photo": ""
        }

    return dict(user)


@router.put("/{firebase_uid}")
def update_user(firebase_uid: str, updated_user: UserUpdate):
    conn = get_connection()
    cursor = conn.cursor()

    cursor.execute(
        "SELECT * FROM users WHERE firebase_uid = ?",
        (firebase_uid,)
    )
    user = cursor.fetchone()

    if not user:
        cursor.execute(
            """
            INSERT INTO users (firebase_uid, email, username, bio, profile_photo)
            VALUES (?, ?, ?, ?, ?)
            """,
            (
                firebase_uid,
                "",
                updated_user.username,
                updated_user.bio,
                updated_user.profile_photo
            )
        )
    else:
        cursor.execute(
            """
            UPDATE users
            SET username = ?, bio = ?, profile_photo = ?
            WHERE firebase_uid = ?
            """,
            (
                updated_user.username,
                updated_user.bio,
                updated_user.profile_photo,
                firebase_uid
            )
        )

    conn.commit()

    cursor.execute(
        "SELECT * FROM users WHERE firebase_uid = ?",
        (firebase_uid,)
    )
    updated = cursor.fetchone()

    conn.close()

    return {
        "message": "User updated successfully",
        "data": dict(updated)
    }