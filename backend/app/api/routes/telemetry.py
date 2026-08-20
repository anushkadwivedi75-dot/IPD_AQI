from typing import List
from fastapi import APIRouter
from app.schemas.telemetry import PersonalTelemetryCreate, PersonalTelemetryResponse

router = APIRouter(prefix="/telemetry", tags=["telemetry"])

_TELEMETRY_STORAGE: List[dict] = []


@router.post("/upload", response_model=PersonalTelemetryResponse)
async def upload_personal_telemetry(payload: List[PersonalTelemetryCreate]):
    for item in payload:
        _TELEMETRY_STORAGE.append(item.model_dump())

    return PersonalTelemetryResponse(
        status="success",
        received=len(payload),
    )


@router.get("/history")
async def get_personal_telemetry_history(user_id: str = "guest", limit: int = 50):
    user_records = [t for t in _TELEMETRY_STORAGE if t.get("user_id") == user_id]
    return user_records[-limit:]
