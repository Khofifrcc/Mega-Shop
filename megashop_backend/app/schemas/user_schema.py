from pydantic import BaseModel, EmailStr
from typing import Optional

class UserCreate(BaseModel):
    firebase_uid: str
    username: str
    email: EmailStr
    bio: Optional[str] = ""
    profile_photo: Optional[str] = ""

class UserUpdate(BaseModel):
    username: Optional[str] = ""
    bio: Optional[str] = ""
    profile_photo: Optional[str] = ""