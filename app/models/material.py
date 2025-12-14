from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, func, JSON
from datetime import datetime
from app.core.db import Base  # ✅ dùng cùng Base với Product để tránh Base trùng lặp


class Material(Base):
    __tablename__ = "materials"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, index=True)
    tenant_id: Mapped[int] = mapped_column(Integer, index=True, nullable=False)
    name: Mapped[str] = mapped_column(String, nullable=False)
    scientific_name: Mapped[str | None] = mapped_column(String)
    stages: Mapped[dict | None] = mapped_column(JSON)
    dpp_notes: Mapped[str | None] = mapped_column(String)
    created_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), server_default=func.now()
    )
    updated_at: Mapped[datetime] = mapped_column(
        DateTime(timezone=True), onupdate=func.now(), server_default=func.now()
    )

    # ✅ Quan hệ ngược tới Product
    products = relationship(
        "Product", back_populates="material", lazy="selectin"
    )

    def __repr__(self):
        return f"<Material id={self.id} name={self.name}>"
