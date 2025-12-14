from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, ForeignKey
from app.core.db import Base

class Domain(Base):
    __tablename__ = "domains"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))
    name: Mapped[str] = mapped_column(String(128), unique=True)
    code: Mapped[str] = mapped_column(String(64), unique=True)

    # If in future you add tenant.domain_id FK, you can add:
    # tenants = relationship("Tenant", back_populates="domain", lazy="selectin")
    tenant = relationship("Tenant", back_populates="domain", lazy="selectin")
