import uuid
from typing import List, Optional
from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import select
from sqlalchemy.ext.asyncio import AsyncSession

from app.db.session import get_db
from app.models.alert import Alert
from app.models.site import Site
from app.schemas.alert import AlertCreate, AlertResponse, AlertTriggerRequest
from app.services.spatial_engine import run_spatial_analysis_for_site

router = APIRouter(prefix="/alerts", tags=["alerts"])


@router.post(
    "",
    response_model=List[AlertResponse],
    status_code=status.HTTP_201_CREATED,
    summary="Create alert directly or trigger spatial & anomaly analysis for a site (Internal)",
)
async def create_or_trigger_alerts(
    payload: AlertCreate,
    db: AsyncSession = Depends(get_db),
):
    if payload.type:
        alert = Alert(
            id=uuid.uuid4(),
            site_id=payload.site_id,
            type=payload.type,
            severity=payload.severity or 1,
            evidence=payload.evidence or {},
        )
        db.add(alert)
        await db.commit()
        await db.refresh(alert)
        return [alert]

    if not payload.site_id:
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Either 'type' or 'site_id' must be provided",
        )

    # Verify site exists
    site_res = await db.execute(select(Site).where(Site.id == payload.site_id))
    site = site_res.scalar_one_or_none()
    if not site:
        raise HTTPException(
            status_code=status.HTTP_404_NOT_FOUND,
            detail=f"Site with ID '{payload.site_id}' not found",
        )

    alerts = await run_spatial_analysis_for_site(db, payload.site_id)
    return alerts


@router.get(
    "",
    response_model=List[AlertResponse],
    summary="Get alerts for site (or all alerts if site_id omitted)",
)
async def get_alerts(
    site_id: Optional[uuid.UUID] = Query(None, description="Optional filter by site ID"),
    db: AsyncSession = Depends(get_db),
):
    query = select(Alert)
    if site_id:
        query = query.where(Alert.site_id == site_id)

    # Order by id descending
    query = query.order_by(Alert.id.desc())

    result = await db.execute(query)
    alerts = result.scalars().all()

    return alerts
