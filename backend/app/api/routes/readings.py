from datetime import datetime, timezone
from typing import List, Union
from fastapi import APIRouter, Depends, status
from geoalchemy2.elements import WKTElement
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.reading import Reading
from app.schemas.reading import (
    BatchReadingCreate,
    BatchReadingResponse,
    ReadingCreate,
)

router = APIRouter(prefix="/readings", tags=["readings"])


@router.post(
    "/batch",
    response_model=BatchReadingResponse,
    status_code=status.HTTP_201_CREATED,
)
async def create_readings_batch(
    payload: Union[BatchReadingCreate, List[ReadingCreate]],
    db: AsyncSession = Depends(get_db),
):
    items = payload.readings if isinstance(payload, BatchReadingCreate) else payload

    new_readings = []
    now = datetime.now(timezone.utc)
    for item in items:
        rec_at = item.recorded_at or now
        location_elem = WKTElement(f"POINT({item.lng} {item.lat})", srid=4326)
        reading = Reading(
            device_id=item.device_id,
            aqi=item.aqi,
            pm25=item.pm25,
            humidity=item.humidity,
            location=location_elem,
            recorded_at=rec_at,
        )
        new_readings.append(reading)

    db.add_all(new_readings)
    await db.commit()

    return BatchReadingResponse(inserted=len(new_readings), status="success")
