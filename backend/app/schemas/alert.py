import uuid
from typing import Any, Dict, Optional
from pydantic import BaseModel


class AlertBase(BaseModel):
    site_id: Optional[uuid.UUID] = None
    type: Optional[str] = None
    severity: Optional[int] = None
    evidence: Optional[Dict[str, Any]] = None


class AlertCreate(AlertBase):
    pass


class AlertResponse(AlertBase):
    id: uuid.UUID

    class Config:
        from_attributes = True


class AlertTriggerRequest(BaseModel):
    site_id: uuid.UUID
