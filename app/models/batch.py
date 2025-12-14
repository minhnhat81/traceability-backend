from __future__ import annotations
from datetime import datetime, timezone, date
from typing import Optional
from sqlalchemy import (
    Integer,
    String,
    Date,
    DateTime,
    ForeignKey,
    Numeric,
    Text,
)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.db import Base


class Batch(Base):
    __tablename__ = "batches"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int] = mapped_column(ForeignKey("tenants.id"), nullable=False)

    # 🔹 Thông tin cơ bản
    code: Mapped[str] = mapped_column(String(64), unique=True, nullable=False)
    product_code: Mapped[str] = mapped_column(String(64), nullable=False)
    mfg_date: Mapped[Optional[date]] = mapped_column(Date)
    country: Mapped[Optional[str]] = mapped_column(String(10), default="VN")
    status: Mapped[Optional[str]] = mapped_column(String(32), default="active")
    quantity: Mapped[Optional[float]] = mapped_column(Numeric(14, 2))
    material_type: Mapped[Optional[str]] = mapped_column(String(64))
    description: Mapped[Optional[str]] = mapped_column(Text)

    # 🔹 Batch chain (4 cấp: Farm → Supplier → Manufacturer → Brand)
    farm_batch_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("batches.id", ondelete="SET NULL")
    )
    supplier_batch_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("batches.id", ondelete="SET NULL")
    )
    manufacturer_batch_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("batches.id", ondelete="SET NULL")
    )
    brand_batch_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("batches.id", ondelete="SET NULL")
    )

    # 🔹 Các mã định danh riêng cho từng cấp
    farm_batch_code: Mapped[Optional[str]] = mapped_column(String(64))
    supplier_batch_code: Mapped[Optional[str]] = mapped_column(String(64))
    manufacturer_batch_code: Mapped[Optional[str]] = mapped_column(String(64))
    brand_batch_code: Mapped[Optional[str]] = mapped_column(String(64))

    # 🔹 Liên kết nguồn gốc
    origin_farm_id: Mapped[Optional[int]] = mapped_column(
        ForeignKey("farms.id", ondelete="SET NULL")
    )

    blockchain_tx_hash: Mapped[Optional[str]] = mapped_column(String(128))
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), default=lambda: datetime.now(timezone.utc)
    )

    # ==================================================
    # 🔗 RELATIONSHIPS
    # ==================================================

    tenant = relationship("Tenant", back_populates="batches", lazy="selectin")
    origin_farm = relationship("Farm", back_populates="batches", lazy="selectin")

    # 🔁 Self-referential chain relationships
    farm_batch = relationship(
        "Batch",
        remote_side="Batch.id",
        foreign_keys=[farm_batch_id],
        backref="child_farms",
        lazy="selectin",
    )
    supplier_batch = relationship(
        "Batch",
        remote_side="Batch.id",
        foreign_keys=[supplier_batch_id],
        backref="child_suppliers",
        lazy="selectin",
    )
    manufacturer_batch = relationship(
        "Batch",
        remote_side="Batch.id",
        foreign_keys=[manufacturer_batch_id],
        backref="child_manufacturers",
        lazy="selectin",
    )
    brand_batch = relationship(
        "Batch",
        remote_side="Batch.id",
        foreign_keys=[brand_batch_id],
        backref="child_brands",
        lazy="selectin",
    )

    # 🔹 Quan hệ với các bảng khác
    product = relationship(
        "Product",
        back_populates="batches",
        primaryjoin="foreign(Batch.product_code) == Product.code",
        viewonly=True,
        lazy="selectin",
    )
    dpp_passport = relationship(
        "DppPassport",
        back_populates="batch",
        uselist=False,
        foreign_keys="[DppPassport.batch_id]",
        lazy="selectin",
    )
    emissions = relationship(
        "Emission", back_populates="batch", cascade="all, delete-orphan", lazy="selectin"
    )

    def __repr__(self) -> str:
        return f"<Batch id={self.id} code={self.code}>"
