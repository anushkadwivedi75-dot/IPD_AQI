from pydantic import BaseModel, Field


class HeatmapPoint(BaseModel):
    lat: float = Field(..., ge=-90.0, le=90.0)
    lng: float = Field(..., ge=-180.0, le=180.0)
    aqi: float
    weight: float
