import uuid
from typing import TYPE_CHECKING, List, Optional
from sqlalchemy import String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.device import Device
    from app.models.community_report import CommunityReport


class User(Base):
    __tablename__ = "users"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )
    phone_or_email: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    role: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    devices: Mapped[List["Device"]] = relationship("Device", back_populates="owner")
    community_reports: Mapped[List["CommunityReport"]] = relationship(
        "CommunityReport", back_populates="user"
    )
