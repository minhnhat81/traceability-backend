from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, text, ForeignKey
from app.core.db import Base

class Customer(Base):
    __tablename__ = "customers"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))
    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    country: Mapped[str | None] = mapped_column(String(64))
    contact_email: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[str | None] = mapped_column(DateTime, server_default=text("NOW()"))

    tenant = relationship("Tenant", back_populates="customers", lazy="selectin")
    customs_records = relationship("Customs", back_populates="customer", lazy="selectin")
