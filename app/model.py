from pydantic import BaseModel, Field, EmailStr


class PostSchema(BaseModel):
    id: int = Field(default=None)
    title: str = Field(...)
    content: str = Field(...)

    class Config:
        json_schema_extra = {
            "example": {
                "title": "Securing FastAPI application with JWT",
                "content": "In this tutorial, you'll learn how to secure your application with JWT.",
            }
        }


class UserSchema(BaseModel):
    full_name: str = Field(...)
    email: EmailStr = Field(...)
    password: str = Field(...)

    class Config:
        json_schema_extra = {
            "example": {
                "full_name": "angel rojas",
                "email": "angel@rojas.com",
                "password": "123456",
            }
        }


class UserLoginSchema(BaseModel):
    email: EmailStr = Field(...)
    password: str = Field(...)

    class Config:
        json_schema_extra = {
            "example": {"email": "angel@rojas.com", "password": "123456"}
        }
