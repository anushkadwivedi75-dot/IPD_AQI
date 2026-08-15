import uuid
from datetime import datetime
from typing import List, Optional
from pydantic import BaseModel, Field


class ReadingBase(BaseModel):
    device_id: Optional[uuid.UUID] = None
    aqi: Optional[int] = Field(None, ge=0, le=500)
    pm25: Optional[float] = Field(None, ge=0.0)
    humidity: Optional[float] = Field(None, ge=0.0, le=100.0)
    lat: float = Field(..., ge=-90.0, le=90.0)
    lng: float = Field(..., ge=-180.0, le=180.0)
    recorded_at: Optional[datetime] = None


class ReadingCreate(ReadingBase):
    pass


class ReadingResponse(ReadingBase):
    id: int

    class Config:
        from_attributes = True


class BatchReadingCreate(BaseModel):
    readings: List[ReadingCreate]


class BatchReadingResponse(BaseModel):
    inserted: int
    status: str = "success"
