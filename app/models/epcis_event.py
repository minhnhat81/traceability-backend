from __future__ import annotations
from typing import Optional, Dict
from datetime import datetime
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, Text, JSON
from sqlalchemy.dialects.postgresql import JSONB
from app.core.db import Base


class EpcisEvent(Base):
    __tablename__ = "epcis_events"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    tenant_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("tenants.id"), nullable=False)

    # EPCIS core fields
    event_id: Mapped[str] = mapped_column(String(255), unique=True, nullable=False)
    event_hash: Mapped[Optional[str]] = mapped_column(String(255), unique=True)
    event_type: Mapped[Optional[str]] = mapped_column(String(32))
    batch_code: Mapped[Optional[str]] = mapped_column(String(64), index=True)
    material_name: Mapped[Optional[str]] = mapped_column(String(32))
    product_code: Mapped[Optional[str]] = mapped_column(String(64), index=True)
    event_time: Mapped[Optional[datetime]] = mapped_column(DateTime(timezone=True))
    event_time_zone_offset: Mapped[Optional[str]] = mapped_column(String(10))
    action: Mapped[Optional[str]] = mapped_column(String(10))
    biz_step: Mapped[Optional[str]] = mapped_column(String(128))
    disposition: Mapped[Optional[str]] = mapped_column(String(128))
    read_point: Mapped[Optional[str]] = mapped_column(String(255))
    biz_location: Mapped[Optional[str]] = mapped_column(String(255))

    # EPCIS data payload
    epc_list: Mapped[Optional[Dict]] = mapped_column(JSONB)
    biz_transaction_list: Mapped[Optional[Dict]] = mapped_column(JSONB)
    ilmd: Mapped[Optional[Dict]] = mapped_column(JSONB)
    extensions: Mapped[Optional[Dict]] = mapped_column(JSONB)
    context: Mapped[Optional[Dict]] = mapped_column(JSONB)  # ✅ EPCIS 2.0 JSON-LD @context

    # 🆕 Các cột bổ sung cho VC & dashboard minh bạch
    doc_bundle_id: Mapped[str] = mapped_column(String(64), nullable=True)
    vc_hash_hex: Mapped[str] = mapped_column(Text(), nullable=True)
    verified: Mapped[bool] = mapped_column(Boolean, default=False)
    raw_payload: Mapped[dict] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True),
        default=lambda: datetime.now(timezone.utc),
        nullable=True
    )


    # --- relationships ---
    tenant = relationship("Tenant", back_populates="epcis_events", lazy="selectin")
    sensor_events = relationship(
        "SensorEvent",
        back_populates="epcis_event",
        cascade="all, delete-orphan",
        lazy="selectin"
    )

    blockchain_anchor = relationship(
        "BlockchainAnchor",
        back_populates="epcis_event",
        uselist=False,  # 1-1
        cascade="all, delete-orphan",
        lazy="selectin"
    )

    # ✅ sửa ở đây: dùng mapped_column + ForeignKey
    dpp_passport_id: Mapped[Optional[int]] = mapped_column(
    Integer,
    ForeignKey("dpp_passports.id", ondelete="CASCADE"),
    nullable=True,
    index=True
    )


    dpp_passport = relationship(
        "DppPassport",
        back_populates="epcis_events",
        lazy="selectin"
    )

    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    def __repr__(self) -> str:
        return f"<EpcisEvent id={self.id}, event_id='{self.event_id}', product='{self.product_code}'>"
