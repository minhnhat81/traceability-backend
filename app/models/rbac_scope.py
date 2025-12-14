from sqlalchemy import Integer, String, ForeignKey
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.orm import Mapped, mapped_column, relationship
from app.core.db import Base

class RbacScope(Base):
    __tablename__ = "rbac_scopes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))
    resource: Mapped[str] = mapped_column(String(64), nullable=False)
    action: Mapped[str] = mapped_column(String(16), nullable=False)
    constraint_expr: Mapped[dict | None] = mapped_column(JSONB)  # 🔹 đổi tên trường ở đây

    tenant = relationship("Tenant", back_populates="rbac_scopes", lazy="selectin")
