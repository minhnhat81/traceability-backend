from fastapi import HTTPException, Depends, Request
from typing import Any, Dict
def verify_jwt(request: Request) -> Dict[str, Any]:
    auth = request.headers.get("Authorization", "")
    if not auth.startswith("Bearer "):
        return {}
    token = auth.split(" ", 1)[1]
    return {"sub": "dev", "token": token}
