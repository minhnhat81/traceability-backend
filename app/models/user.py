from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, text
from datetime import datetime
from app.core.db import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))

    # 🧩 username dùng để đăng nhập & phân biệt user
    username: Mapped[str] = mapped_column(String(64), unique=True, index=True, nullable=False)

    # 🧩 thông tin cơ bản
    name: Mapped[str | None] = mapped_column(String(128))
    email: Mapped[str | None] = mapped_column(String(255), unique=True, index=True)
    role: Mapped[str | None] = mapped_column(String(32))  # superadmin/admin/tenant_admin/data_staff/supplier

    # 🧩 bảo mật
    password_hash: Mapped[str | None] = mapped_column(String(255))
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    created_at: Mapped[datetime | None] = mapped_column(DateTime, server_default=text("NOW()"))

    # 🧩 liên kết
    tenant = relationship("Tenant", back_populates="users", lazy="selectin")
    supplier = relationship("Supplier", back_populates="user", uselist=False)
    rbac_role_bindings = relationship("RbacRoleBinding", back_populates="user", lazy="selectin")
