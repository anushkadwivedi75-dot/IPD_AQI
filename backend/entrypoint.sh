#!/bin/sh
set -e

echo "[AirSentine1 API] Checking database migrations..."
if [ -f "/app/alembic.ini" ]; then
    echo "[AirSentine1 API] Running Alembic migrations to head..."
    alembic upgrade head || echo "[AirSentine1 API] Migration notice: already up to date or proceeding."
fi

echo "[AirSentine1 API] Launching FastAPI service..."
exec "$@"
