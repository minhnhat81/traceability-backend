from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, text, ForeignKey
from app.core.db import Base

class Brand(Base):
    __tablename__ = "brands"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))
    name: Mapped[str] = mapped_column(String(128), unique=True, index=True)
    owner: Mapped[str | None] = mapped_column(String(128))
    website: Mapped[str | None] = mapped_column(String(255))
    created_at: Mapped[str | None] = mapped_column(DateTime, server_default=text("NOW()"))

    tenant = relationship("Tenant", back_populates="brands", lazy="selectin")
