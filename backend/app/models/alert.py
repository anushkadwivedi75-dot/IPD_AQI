import uuid
from typing import TYPE_CHECKING, Any, Dict, Optional
from sqlalchemy import ForeignKey, SmallInteger, String, text
from sqlalchemy.dialects.postgresql import JSONB, UUID
from sqlalchemy.orm import Mapped, mapped_column, relationship

from app.models.base import Base

if TYPE_CHECKING:
    from app.models.site import Site


class Alert(Base):
    __tablename__ = "alerts"

    id: Mapped[uuid.UUID] = mapped_column(
        UUID(as_uuid=True),
        primary_key=True,
        default=uuid.uuid4,
        server_default=text("gen_random_uuid()"),
    )
    site_id: Mapped[Optional[uuid.UUID]] = mapped_column(
        UUID(as_uuid=True),
        ForeignKey("sites.id", ondelete="CASCADE"),
        nullable=True,
    )
    type: Mapped[Optional[str]] = mapped_column(String, nullable=True)
    severity: Mapped[Optional[int]] = mapped_column(SmallInteger, nullable=True)
    evidence: Mapped[Optional[Dict[str, Any]]] = mapped_column(JSONB, nullable=True)

    site: Mapped[Optional["Site"]] = relationship("Site", back_populates="alerts")
