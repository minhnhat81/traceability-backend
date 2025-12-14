from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, text, ForeignKey, JSON
from app.core.db import Base

class Supplier(Base):
    __tablename__ = "suppliers"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    country: Mapped[str | None] = mapped_column(String(64))
    contact_email: Mapped[str | None] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(64))
    address: Mapped[str | None] = mapped_column(String(255))
    factory_location: Mapped[str | None] = mapped_column(String(255))
    certification: Mapped[dict | None] = mapped_column(JSON)  # ✅ kiểu JSONB trong PostgreSQL
    user_id: Mapped[int | None] = mapped_column(ForeignKey("users.id"))
    created_at: Mapped[str | None] = mapped_column(DateTime, server_default=text("NOW()"))

    # Quan hệ
    tenant = relationship("Tenant", back_populates="suppliers", lazy="selectin")
    user = relationship("User", back_populates="supplier", lazy="selectin")
