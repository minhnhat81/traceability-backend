from fastapi import APIRouter
from app.utils.pagination import Page, PageMeta

router = APIRouter()

@router.get("/health")
def health():
    return {"ok": True}
