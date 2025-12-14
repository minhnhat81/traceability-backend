from __future__ import annotations
from typing import Optional
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime, timezone
from app.core.db import Base


class BlockchainAnchor(Base):
    __tablename__ = "blockchain_anchors"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("tenants.id"))

    # Anchor metadata
    anchor_type: Mapped[Optional[str]] = mapped_column(String(64))
    ref: Mapped[Optional[str]] = mapped_column(String(255))
    tx_hash: Mapped[Optional[str]] = mapped_column(String(128))
    network: Mapped[Optional[str]] = mapped_column(String(64))
    meta: Mapped[Optional[dict]] = mapped_column(JSONB)

    # Extended blockchain verification fields
    bundle_id: Mapped[Optional[str]] = mapped_column(String(255))
    batch_hash: Mapped[Optional[str]] = mapped_column(String(128))
    block_number: Mapped[Optional[int]] = mapped_column(Integer)
    status: Mapped[str] = mapped_column(String(32), default="pending")

    # Foreign keys to link EPCIS & DPP
    dpp_id: Mapped[Optional[int]] = mapped_column(ForeignKey("dpp_passports.id"))
    epcis_event_id: Mapped[Optional[int]] = mapped_column(ForeignKey("epcis_events.id"))

    # Audit timestamps
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # Relationships
    tenant = relationship("Tenant", back_populates="blockchain_anchors", lazy="selectin")
    dpp_passport = relationship("DppPassport", back_populates="blockchain_anchors", lazy="selectin")
    epcis_event  = relationship("EpcisEvent", back_populates="blockchain_anchor", lazy="selectin")


    def __repr__(self) -> str:
        return f"<BlockchainAnchor id={self.id} tx={self.tx_hash} status={self.status}>"
