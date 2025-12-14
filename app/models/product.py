from sqlalchemy.orm import Mapped, mapped_column, relationship, foreign
from sqlalchemy import Integer, String, DateTime, text, ForeignKey
from datetime import datetime
from app.core.db import Base


class Product(Base):
    __tablename__ = "products"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(ForeignKey("tenants.id"))

    # ✅ liên kết với bảng materials
    material_id: Mapped[int | None] = mapped_column(
        ForeignKey("materials.id"), nullable=True
    )

    code: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(255))
    category: Mapped[str | None] = mapped_column(String(128))
    created_at: Mapped[datetime | None] = mapped_column(
        DateTime, server_default=text("NOW()")
    )

    # ================== RELATIONSHIPS ==================
    tenant = relationship("Tenant", back_populates="products", lazy="selectin")

    # ✅ liên kết ngược đến Material
    material = relationship(
        "Material",
        back_populates="products",
        lazy="selectin",
    )

    # Giữ nguyên các quan hệ cũ
    dpp_templates = relationship(
        "DppTemplate",
        back_populates="product",
        cascade="all,delete-orphan",
        lazy="selectin",
    )

    batches = relationship(
        "Batch",
        back_populates="product",
        primaryjoin="foreign(Batch.product_code) == Product.code",
        viewonly=True,
        lazy="selectin",
    )

    def __repr__(self):
        return f"<Product code={self.code} name={self.name}>"
