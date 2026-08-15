import statistics
import uuid
from datetime import datetime, timedelta, timezone
from unittest.mock import AsyncMock, MagicMock

import pytest
import numpy as np

from app.models.alert import Alert
from app.models.reading import Reading
from app.models.site import Site
from app.services.spatial_engine import (
    ANOMALY_CONTAMINATION_RATE,
    ANOMALY_MIN_SAMPLES,
    DIVERGENCE_RADIUS_METERS,
    DIVERGENCE_THRESHOLD_AQI,
    DIVERGENCE_TIME_WINDOW_MINUTES,
    check_site_anomaly,
    check_site_divergence,
    run_spatial_analysis_for_site,
)


@pytest.mark.asyncio
async def test_constants_defined():
    assert DIVERGENCE_RADIUS_METERS == 300.0
    assert DIVERGENCE_TIME_WINDOW_MINUTES == 60
    assert DIVERGENCE_THRESHOLD_AQI == 30.0
    assert ANOMALY_CONTAMINATION_RATE == 0.05
    assert ANOMALY_MIN_SAMPLES == 5


@pytest.mark.asyncio
async def test_check_site_divergence_no_site():
    mock_db = AsyncMock()
    mock_res = MagicMock()
    mock_res.scalar_one_or_none.return_value = None
    mock_db.execute.return_value = mock_res

    alert = await check_site_divergence(mock_db, uuid.uuid4())
    assert alert is None


@pytest.mark.asyncio
async def test_check_site_divergence_with_divergence_alert():
    mock_db = AsyncMock()
    site_id = uuid.uuid4()
    off_device_id = uuid.uuid4()
    comm_device_id = uuid.uuid4()

    site = Site(id=site_id, official_device_id=off_device_id, location="POINT(77.2090 28.6139)")

    # Official reading AQI = 150
    official_reading = Reading(
        id=1, device_id=off_device_id, aqi=150, recorded_at=datetime.now(timezone.utc)
    )

    # Community readings median AQI = 50 (Divergence = 100 > 30.0)
    comm_row1 = MagicMock(id=2, device_id=comm_device_id, aqi=50, pm25=15.0, humidity=40.0, lat=28.614, lng=77.209, recorded_at=datetime.now(timezone.utc))
    comm_row2 = MagicMock(id=3, device_id=comm_device_id, aqi=50, pm25=15.0, humidity=40.0, lat=28.614, lng=77.209, recorded_at=datetime.now(timezone.utc))

    mock_res_site = MagicMock()
    mock_res_site.scalar_one_or_none.return_value = site

    mock_res_off = MagicMock()
    mock_res_off.scalar_one_or_none.return_value = official_reading

    mock_res_comm = MagicMock()
    mock_res_comm.all.return_value = [comm_row1, comm_row2]

    mock_db.execute.side_effect = [mock_res_site, mock_res_off, mock_res_comm]

    alert = await check_site_divergence(mock_db, site_id)
    assert alert is not None
    assert alert.type == "divergence"
    assert alert.site_id == site_id
    assert alert.evidence["official_aqi"] == 150
    assert alert.evidence["community_median_aqi"] == 50.0
    assert alert.evidence["divergence"] == 100.0


@pytest.mark.asyncio
async def test_check_site_anomaly_min_samples():
    mock_db = AsyncMock()
    mock_res_site = MagicMock()
    site = Site(id=uuid.uuid4(), location="POINT(77.2090 28.6139)")
    mock_res_site.scalar_one_or_none.return_value = site

    mock_res_readings = MagicMock()
    readings = [
        Reading(id=i, aqi=50 + i, pm25=20.0, humidity=50.0, recorded_at=datetime.now(timezone.utc))
        for i in range(3)
    ]
    mock_res_readings.scalars.return_value.all.return_value = readings

    mock_db.execute.side_effect = [mock_res_site, mock_res_readings]

    alert = await check_site_anomaly(mock_db, site.id)
    assert alert is None


@pytest.mark.asyncio
async def test_run_spatial_analysis_for_site():
    mock_db = AsyncMock()
    site_id = uuid.uuid4()

    # Mock no site found -> returns []
    mock_res_site = MagicMock()
    mock_res_site.scalar_one_or_none.return_value = None
    mock_db.execute.return_value = mock_res_site

    alerts = await run_spatial_analysis_for_site(mock_db, site_id)
    assert alerts == []
