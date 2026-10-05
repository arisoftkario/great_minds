from pydantic import BaseModel, EmailStr
from typing import Optional
from datetime import datetime
from app.models.user import UserRole, UserStatus

class UserBase(BaseModel):
    email: EmailStr
    full_name: str
    role: UserRole = UserRole.AGENT
    status: UserStatus = UserStatus.ACTIVE

class UserCreate(UserBase):
    password: str

class UserUpdate(BaseModel):
    email: Optional[EmailStr] = None
    full_name: Optional[str] = None
    role: Optional[UserRole] = None
    status: Optional[UserStatus] = None
    password: Optional[str] = None

class UserResponse(UserBase):
    id: str
    created_at: datetime
    last_login_at: Optional[datetime] = None

    class Config:
        from_attributes = True
