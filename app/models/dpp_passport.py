from __future__ import annotations
from datetime import datetime, timezone
from typing import Optional, Dict, Any
from sqlalchemy import Integer, String, DateTime, Text, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.db import Base


class DppPassport(Base):
    __tablename__ = "dpp_passports"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[Optional[int]] = mapped_column(ForeignKey("tenants.id", ondelete="CASCADE"))
    batch_id: Mapped[Optional[int]] = mapped_column(ForeignKey("batches.id", ondelete="SET NULL"))
    version: Mapped[str] = mapped_column(Text, default="1.0")

    # 16 nhóm dữ liệu
    product_description: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    composition: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    supply_chain: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    transport: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    documentation: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    environmental_impact: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    social_impact: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    animal_welfare: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    circularity: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    health_safety: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    brand_info: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    digital_identity: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    quantity_info: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    cost_info: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    use_phase: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    end_of_life: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)

    linked_epcis: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    linked_blockchain: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB)
    status: Mapped[str] = mapped_column(String(32), default="draft")

    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=lambda: datetime.now(timezone.utc))

    # ✅ Relationship: xác định rõ foreign_keys
    batch               = relationship("Batch", back_populates="dpp_passport",
                                   foreign_keys="[DppPassport.batch_id]", lazy="selectin")
    tenant              = relationship("Tenant", back_populates="dpp_passports", lazy="selectin")
    blockchain_anchors  = relationship("BlockchainAnchor", back_populates="dpp_passport",
                                   cascade="all, delete-orphan", lazy="selectin")
    # nếu bạn có mapping 1-n từ DPP → các EPCIS đã gắn:
    epcis_events        = relationship("EpcisEvent", back_populates="dpp_passport", lazy="selectin")


    def __repr__(self):
        return f"<DppPassport id={self.id} batch_id={self.batch_id}>"
