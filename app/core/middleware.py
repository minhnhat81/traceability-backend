from typing import Callable
from fastapi import Request, HTTPException, status
from app.core.security import verify_jwt
from app.core.config import settings

def get_current_user_claims(request: Request):
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Missing bearer token")
    token = auth.split(" ", 1)[1].strip()
    return verify_jwt(token)
