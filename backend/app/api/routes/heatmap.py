from datetime import datetime, timedelta, timezone
from typing import List
from fastapi import APIRouter, Depends, Query
from geoalchemy2 import Geometry
from sqlalchemy import cast, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.reading import Reading
from app.schemas.heatmap import HeatmapPoint

router = APIRouter(prefix="/heatmap", tags=["heatmap"])


@router.get("", response_model=List[HeatmapPoint])
async def get_heatmap(
    min_lat: float = Query(..., ge=-90.0, le=90.0),
    min_lng: float = Query(..., ge=-180.0, le=180.0),
    max_lat: float = Query(..., ge=-90.0, le=90.0),
    max_lng: float = Query(..., ge=-180.0, le=180.0),
    db: AsyncSession = Depends(get_db),
):
    cutoff = datetime.now(timezone.utc) - timedelta(hours=24)
    loc_geom = cast(Reading.location, Geometry)
    lat_expr = func.ST_Y(loc_geom)
    lng_expr = func.ST_X(loc_geom)

    bbox_geom = func.ST_SetSRID(
        func.ST_MakeEnvelope(min_lng, min_lat, max_lng, max_lat),
        4326,
    )

    query = (
        select(
            lat_expr.label("lat"),
            lng_expr.label("lng"),
            func.avg(Reading.aqi).label("aqi"),
            func.count().label("weight"),
        )
        .where(
            Reading.recorded_at >= cutoff,
            func.ST_Intersects(loc_geom, bbox_geom),
        )
        .group_by(lat_expr, lng_expr)
    )

    result = await db.execute(query)
    rows = result.all()

    points = [
        HeatmapPoint(
            lat=round(float(row.lat), 6),
            lng=round(float(row.lng), 6),
            aqi=round(float(row.aqi or 0.0), 2),
            weight=float(row.weight or 1.0),
        )
        for row in rows
        if row.lat is not None and row.lng is not None
    ]

    return points
