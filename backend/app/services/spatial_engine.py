import statistics
import uuid
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional

import numpy as np
from geoalchemy2 import Geometry
from sklearn.ensemble import IsolationForest
from sqlalchemy import cast, func, select
from sqlalchemy.ext.asyncio import AsyncSession

from app.models.alert import Alert
from app.models.reading import Reading
from app.models.site import Site

# =============================================================================
# NAMED PILOT CONFIGURATION CONSTANTS (Tuning Parameters)
# =============================================================================
DIVERGENCE_RADIUS_METERS: float = 300.0
DIVERGENCE_TIME_WINDOW_MINUTES: int = 60
DIVERGENCE_THRESHOLD_AQI: float = 30.0
ANOMALY_CONTAMINATION_RATE: float = 0.05
ANOMALY_MIN_SAMPLES: int = 5
# =============================================================================


async def check_site_divergence(
    db: AsyncSession,
    site_id: uuid.UUID,
) -> Optional[Alert]:
    """Find community readings within 300m over the last 1 hour, compute median AQI,

    and compare against the site's most recent official reading.
    If divergence exceeds DIVERGENCE_THRESHOLD_AQI, create an Alert row.
    """
    # 1. Fetch site
    site_res = await db.execute(select(Site).where(Site.id == site_id))
    site = site_res.scalar_one_or_none()
    if not site or not site.official_device_id or not site.location:
        return None

    # 2. Fetch latest official reading
    off_res = await db.execute(
        select(Reading)
        .where(Reading.device_id == site.official_device_id)
        .order_by(Reading.recorded_at.desc())
        .limit(1)
    )
    official_reading = off_res.scalar_one_or_none()
    if not official_reading or official_reading.aqi is None:
        return None

    # 3. Query community readings within 300m in the last hour
    cutoff = datetime.now(timezone.utc) - timedelta(minutes=DIVERGENCE_TIME_WINDOW_MINUTES)
    loc_geom = cast(Reading.location, Geometry)

    query = select(
        Reading.id,
        Reading.device_id,
        Reading.aqi,
        Reading.pm25,
        Reading.humidity,
        func.ST_Y(loc_geom).label("lat"),
        func.ST_X(loc_geom).label("lng"),
        Reading.recorded_at,
    ).where(
        Reading.device_id != site.official_device_id,
        func.ST_DWithin(Reading.location, site.location, DIVERGENCE_RADIUS_METERS),
        Reading.recorded_at >= cutoff,
    )

    comm_res = await db.execute(query)
    community_rows = comm_res.all()

    valid_comm_aqis = [r.aqi for r in community_rows if r.aqi is not None]
    if not valid_comm_aqis:
        return None

    # 4. Compute median community AQI
    comm_median_aqi = statistics.median(valid_comm_aqis)
    divergence = abs(float(comm_median_aqi) - float(official_reading.aqi))

    # 5. Check threshold
    if divergence > DIVERGENCE_THRESHOLD_AQI:
        evidence: Dict[str, Any] = {
            "official_device_id": str(site.official_device_id),
            "official_aqi": official_reading.aqi,
            "community_median_aqi": round(float(comm_median_aqi), 2),
            "divergence": round(float(divergence), 2),
            "threshold": DIVERGENCE_THRESHOLD_AQI,
            "radius_meters": DIVERGENCE_RADIUS_METERS,
            "time_window_minutes": DIVERGENCE_TIME_WINDOW_MINUTES,
            "community_readings_count": len(valid_comm_aqis),
            "community_readings": [
                {
                    "id": r.id,
                    "device_id": str(r.device_id) if r.device_id else None,
                    "aqi": r.aqi,
                    "lat": float(r.lat) if r.lat is not None else None,
                    "lng": float(r.lng) if r.lng is not None else None,
                    "recorded_at": r.recorded_at.isoformat() if r.recorded_at else None,
                }
                for r in community_rows
            ],
        }

        alert = Alert(
            id=uuid.uuid4(),
            site_id=site_id,
            type="divergence",
            severity=2 if divergence < 50 else 3,
            evidence=evidence,
        )
        db.add(alert)
        return alert

    return None


async def check_site_anomaly(
    db: AsyncSession,
    site_id: uuid.UUID,
) -> Optional[Alert]:
    """Isolation-forest-based anomaly scorer over a site's time-series readings."""
    site_res = await db.execute(select(Site).where(Site.id == site_id))
    site = site_res.scalar_one_or_none()
    if not site or not site.location:
        return None

    # Query recent readings for site's official device (or near site) over last 48 hours
    cutoff = datetime.now(timezone.utc) - timedelta(hours=48)
    if site.official_device_id:
        where_cond = (Reading.device_id == site.official_device_id) & (Reading.recorded_at >= cutoff)
    else:
        where_cond = func.ST_DWithin(Reading.location, site.location, 500) & (Reading.recorded_at >= cutoff)

    query = select(Reading).where(where_cond).order_by(Reading.recorded_at.asc())

    readings_res = await db.execute(query)
    readings = readings_res.scalars().all()

    if len(readings) < ANOMALY_MIN_SAMPLES:
        return None

    features = [
        [
            float(r.aqi or 0),
            float(r.pm25 or 0.0),
            float(r.humidity or 0.0),
        ]
        for r in readings
    ]

    X = np.array(features)
    model = IsolationForest(
        contamination=ANOMALY_CONTAMINATION_RATE,
        random_state=42,
    )
    preds = model.fit_predict(X)
    scores = model.decision_function(X)

    # Check if latest reading is flagged as anomaly
    if preds[-1] == -1:
        latest_r = readings[-1]
        evidence: Dict[str, Any] = {
            "reading_id": latest_r.id,
            "device_id": str(latest_r.device_id) if latest_r.device_id else None,
            "aqi": latest_r.aqi,
            "pm25": latest_r.pm25,
            "humidity": latest_r.humidity,
            "anomaly_score": round(float(scores[-1]), 4),
            "contamination_rate": ANOMALY_CONTAMINATION_RATE,
            "total_samples_analyzed": len(readings),
        }

        alert = Alert(
            id=uuid.uuid4(),
            site_id=site_id,
            type="anomaly",
            severity=3,
            evidence=evidence,
        )
        db.add(alert)
        return alert

    return None


async def run_spatial_analysis_for_site(
    db: AsyncSession,
    site_id: uuid.UUID,
) -> List[Alert]:
    """Runs spatial divergence and IsolationForest anomaly checks for a site,

    persists alerts to DB, and returns created alerts.
    """
    created_alerts = []

    divergence_alert = await check_site_divergence(db, site_id)
    if divergence_alert:
        created_alerts.append(divergence_alert)

    anomaly_alert = await check_site_anomaly(db, site_id)
    if anomaly_alert:
        created_alerts.append(anomaly_alert)

    if created_alerts:
        await db.commit()
        for a in created_alerts:
            await db.refresh(a)

    return created_alerts
