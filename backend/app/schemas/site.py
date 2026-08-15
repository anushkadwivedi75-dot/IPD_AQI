import uuid
from typing import List, Optional
from pydantic import BaseModel, Field
from app.schemas.reading import ReadingResponse


class SiteBase(BaseModel):
    name: Optional[str] = None
    lat: Optional[float] = Field(None, ge=-90.0, le=90.0)
    lng: Optional[float] = Field(None, ge=-180.0, le=180.0)
    official_device_id: Optional[uuid.UUID] = None
    status: Optional[str] = None


class SiteCreate(SiteBase):
    pass


class SiteResponse(SiteBase):
    id: uuid.UUID

    class Config:
        from_attributes = True


class SiteHistoryResponse(BaseModel):
    site_id: uuid.UUID
    site_name: Optional[str] = None
    hours: int
    readings: List[ReadingResponse]
