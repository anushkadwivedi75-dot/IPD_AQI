from datetime import datetime
from typing import Optional
from pydantic import BaseModel


class PersonalTelemetryCreate(BaseModel):
    user_id: str
    device_id: str
    device_name: Optional[str] = "AirSentinel BLE Pod"
    aqi: int
    pm25: float
    pm10: float
    temperature: float
    humidity: float
    heart_rate: Optional[int] = None
    lat: float
    lng: float
    timestamp: datetime


class PersonalTelemetryResponse(BaseModel):
    status: str
    received: int
