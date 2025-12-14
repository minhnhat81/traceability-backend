from sqlalchemy import func
from fastapi import APIRouter, Depends
from app.utils.pagination import Page, PageMeta
from sqlalchemy.orm import Session
from app.core.db import get_db
from app.models.event import Event
from app.schemas.event import EventCreate, EventOut

router = APIRouter(prefix="/api/events", tags=["events"])

@router.get("", response_model=list[EventOut])
def list_events(db: Session = Depends(get_db), limit: int = 50, offset: int = 0):
    return db.query(Event).order_by(Event.id.desc()).limit(limit).offset(offset).all()

@router.post("", response_model=EventOut, status_code=201)
def create_event(payload: EventCreate, db: Session = Depends(get_db)):
    obj = Event(**payload.model_dump())
    db.add(obj)
    db.commit()
    db.refresh(obj)
    return obj
