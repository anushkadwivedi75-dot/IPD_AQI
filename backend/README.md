# AirSentine1 Backend Service

FastAPI (Python) backend service with PostGIS database container, SQLAlchemy Async engine, Alembic migrations, and Docker Compose orchestration.

## Service Architecture

```
backend/
  app/
    main.py                 # FastAPI entrypoint
    core/config.py          # Env-based settings via pydantic-settings
    db/session.py           # Async SQLAlchemy engine + session
    models/                 # SQLAlchemy models
    schemas/                # Pydantic request/response schemas
    api/routes/             # API endpoints
    services/               # Business logic services
  alembic/                  # Database migration scripts
  docker-compose.yml        # PostGIS database + FastAPI API service
  requirements.txt          # Python dependencies
  .env.example              # Environment variables template
  README.md
```

---

## Getting Started

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) & [Docker Compose](https://docs.docker.com/compose/install/) installed on your machine.

---

### Step 1: Environment Setup

Copy `.env.example` to `.env` in the `backend/` directory:

```bash
cp .env.example .env
```

---

### Step 2: Build & Start Docker Services

Build the container images and start both the **PostGIS database** (`db`) and **FastAPI app** (`api`) in detached mode:

```bash
docker compose up --build -d
```

> The `api` service automatically waits until the `db` service healthcheck passes (`pg_isready`).

To inspect running containers:

```bash
docker compose ps
```

To view live container logs:

```bash
docker compose logs -f api
```

---

### Step 3: Run Alembic Database Migrations

To apply database migrations to the PostGIS instance inside the running container:

```bash
docker compose exec api alembic upgrade head
```

#### Creating New Migrations (when models are added/updated):

```bash
docker compose exec api alembic revision --autogenerate -m "describe_migration"
```

---

### Step 4: Verify `/health` Endpoint

Test the healthcheck endpoint using `curl` or open it in your browser:

#### Via `curl`:

```bash
curl http://localhost:8000/health
```

#### Expected Response:

```json
{"status":"ok"}
```

#### Documentation Links:
- Interactive API Docs (Swagger UI): [http://localhost:8000/docs](http://localhost:8000/docs)
- ReDoc API Docs: [http://localhost:8000/redoc](http://localhost:8000/redoc)

---

### Step 5: Stop Services

To stop and remove containers and networks (persisting the database volume):

```bash
docker compose down
```

To completely reset services and remove persistent database volumes:

```bash
docker compose down -v
```
