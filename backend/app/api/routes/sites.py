import uuid
from datetime import datetime, timedelta, timezone
from fastapi import APIRouter, Depends, HTTPException, Query, status
from geoalchemy2 import Geometry
from sqlalchemy import cast, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.site import Site
from app.models.reading import Reading
from app.schemas.reading import ReadingResponse
from app.schemas.site import SiteHistoryResponse

router = APIRouter(prefix="/sites", tags=["sites"])


@router.get("/{site_id}/history", response_model=SiteHistoryResponse)
async def get_site_history(
    site_id: uuid.UUID,
    hours: int = Query(24, ge=1, le=720),
    db: AsyncSession = Depends(get_db),
):
    # Fetch site by ID
    site_result = await db.execute(select(Site).where(Site.id == site_id))
    site = site_result.scalar_one_or_none()

    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Site with ID '{site_id}' not found",
        )

    cutoff = datetime.now(timezone.utc) - timedelta(hours=hours)
    loc_geom = cast(Reading.location, Geometry)

    query = (
        select(
            Reading.id,
            Reading.device_id,
            Reading.aqi,
            Reading.pm25,
            Reading.humidity,
            func.ST_Y(loc_geom).label("lat"),
            func.ST_X(loc_geom).label("lng"),
            Reading.recorded_at,
        )
        .where(
            func.ST_DWithin(Reading.location, site.location, 500),
            Reading.recorded_at >= cutoff,
        )
        .order_by(Reading.recorded_at.asc())
    )

    result = await db.execute(query)
    rows = result.all()

    readings = [
        ReadingResponse(
            id=row.id,
            device_id=row.device_id,
            aqi=row.aqi,
            pm25=row.pm25,
            humidity=row.humidity,
            lat=float(row.lat) if row.lat is not None else 0.0,
            lng=float(row.lng) if row.lng is not None else 0.0,
            recorded_at=row.recorded_at,
        )
        for row in rows
    ]

    return SiteHistoryResponse(
        site_id=site.id,
        site_name=site.name,
        hours=hours,
        readings=readings,
    )
