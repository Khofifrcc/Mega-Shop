from pydantic import BaseModel, EmailStr
from typing import Optional

class UserCreate(BaseModel):
    firebase_uid: str
    username: str
    email: EmailStr
    bio: Optional[str] = None
    profile_photo: Optional[str] = None

class UserUpdate(BaseModel):
    username: str
    bio: Optional[str] = None
    profile_photo: Optional[str] = None