import uuid
from unittest.mock import AsyncMock, MagicMock, patch

import pytest
from fastapi.testclient import TestClient

from app.main import app
from app.db.session import get_db
from app.models.alert import Alert

client = TestClient(app)


def test_get_alerts_endpoint():
    mock_session = AsyncMock()
    mock_res = MagicMock()
    
    alert1 = Alert(id=uuid.uuid4(), site_id=uuid.uuid4(), type="divergence", severity=2, evidence={})
    alert2 = Alert(id=uuid.uuid4(), site_id=uuid.uuid4(), type="anomaly", severity=3, evidence={})
    
    mock_res.scalars.return_value.all.return_value = [alert1, alert2]
    mock_session.execute.return_value = mock_res

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    try:
        response = client.get("/api/alerts")
        assert response.status_code == 200
        data = response.json()
        assert len(data) == 2
        assert data[0]["type"] == "divergence"
        assert data[1]["type"] == "anomaly"
    finally:
        app.dependency_overrides.clear()


def test_post_alerts_create_direct():
    mock_session = AsyncMock()
    site_id = str(uuid.uuid4())

    async def override_get_db():
        yield mock_session

    app.dependency_overrides[get_db] = override_get_db

    try:
        payload = {
            "site_id": site_id,
            "type": "divergence",
            "severity": 2,
            "evidence": {"divergence": 45.0}
        }
        response = client.post("/api/alerts", json=payload)
        assert response.status_code == 201
        data = response.json()
        assert len(data) == 1
        assert data[0]["site_id"] == site_id
        assert data[0]["type"] == "divergence"
    finally:
        app.dependency_overrides.clear()
