from __future__ import annotations
from typing import Optional, List
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.db import Base

class PolygonLog(Base):
    __tablename__ = "polygon_logs"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tx_hash: Mapped[Optional[str]] = mapped_column(String(128))
    method: Mapped[Optional[str]] = mapped_column(String(128))
    params: Mapped[Optional[dict]] = mapped_column(JSONB)
    result: Mapped[Optional[dict]] = mapped_column(JSONB)
