import uuid
from typing import TYPE_CHECKING, List, Optional
from geoalchemy2 import Geography
from sqlalchemy import ForeignKey, String, text
from sqlalchemy.dialects.postgresql import UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.device import Device
    from app.models.community_report import CommunityReport
    from app.models.alert import Alert


class Site(Base):
    __tablename__ = "sites"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )
    name: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    location: Mapped[Optional[str]] = mapped_column(
        Geography(geometry_type="POINT", srid=4326, spatial_index=True),
        nullable=True,
    )
    official_device_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("devices.id", ondelete="SET NULL"),
        nullable=True,
    )
    status: Mapped[Optional[str]] = mapped_column(String, nullable=True)

    official_device: Mapped[Optional["Device"]] = relationship("Device", back_populates="sites")
    community_reports: Mapped[List["CommunityReport"]] = relationship(
        "CommunityReport", back_populates="site"
    )
    alerts: Mapped[List["Alert"]] = relationship("Alert", back_populates="site")
