from __future__ import annotations
from typing import Optional, List
from sqlalchemy.orm import Mapped, mapped_column, relationship
from sqlalchemy import Integer, String, DateTime, Boolean, ForeignKey, Text
from sqlalchemy.dialects.postgresql import JSONB
from datetime import datetime
from app.core.db import Base

class RbacRole(Base):
    __tablename__ = "rbac_roles"
    id: Mapped[int] = mapped_column(Integer, primary_key=True)
    tenant_id: Mapped[int | None] = mapped_column(Integer, ForeignKey("tenants.id"))
    name: Mapped[str] = mapped_column(String(64))
    description: Mapped[Optional[str]] = mapped_column(Text)

    # Relations
    tenant = relationship("Tenant", back_populates="rbac_roles", lazy="selectin")
    bindings = relationship("RbacRoleBinding", back_populates="role", cascade="all, delete-orphan", lazy="selectin")
    permissions = relationship("RbacPermission", back_populates="role", lazy="selectin")
    menus = relationship("UiMenu", back_populates="role", lazy="selectin")
