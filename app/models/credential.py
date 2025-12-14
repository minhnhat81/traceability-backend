from __future__ import annotations
from typing import Optional
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, JSON, ForeignKey
from datetime import datetime
from app.core.db import Base

class Credential(Base):
    __tablename__ = "credentials"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))
    subject: Mapped[Optional[str]] = mapped_column(String(255))
    type: Mapped[Optional[str]] = mapped_column(String(64))
    jws: Mapped[Optional[str]] = mapped_column(String)
    status: Mapped[Optional[str]] = mapped_column(String(32))
    hash_hex: Mapped[Optional[str]] = mapped_column(String(128))
    vc_payload: Mapped[Optional[dict]] = mapped_column(JSON)
    proof_tx: Mapped[Optional[str]] = mapped_column(String(128))
    chain: Mapped[Optional[str]] = mapped_column(String(64))
    issued_at: Mapped[Optional[datetime]] = mapped_column(DateTime)
    created_at: Mapped[Optional[datetime]] = mapped_column(DateTime, default=datetime.utcnow)

    tenant = relationship("Tenant", back_populates="credentials", lazy="selectin")
