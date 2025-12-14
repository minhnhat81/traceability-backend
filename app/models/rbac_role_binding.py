from __future__ import annotations
from typing import Optional, List
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.db import Base

class RbacRoleBinding(Base):
    __tablename__ = "rbac_role_bindings"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))
    user_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("users.id"))
    role_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("rbac_roles.id"))

    tenant = relationship("Tenant", back_populates="rbac_role_bindings", lazy="selectin")
    user = relationship("User", back_populates="rbac_role_bindings", lazy="selectin")
    role = relationship("RbacRole", back_populates="bindings", lazy="selectin")
