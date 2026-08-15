from fastapi import APIRouter
from app.api.routes.health import router as health_router
from app.api.routes.readings import router as readings_router
from app.api.routes.heatmap import router as heatmap_router
from app.api.routes.sites import router as sites_router
from app.api.routes.alerts import router as alerts_router

api_router = APIRouter(prefix="/api")
api_router.include_router(health_router, tags=["health"])
api_router.include_router(readings_router)
api_router.include_router(heatmap_router)
api_router.include_router(sites_router)
api_router.include_router(alerts_router)


