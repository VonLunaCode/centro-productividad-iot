import asyncio
from contextlib import asynccontextmanager
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from .database import init_db
from .mqtt_subscriber import run_subscriber
from .routes import readings, calibration

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    await init_db()
    # Run MQTT subscriber in background
    mqtt_task = asyncio.create_task(run_subscriber())
    yield
    # Shutdown
    mqtt_task.cancel()
    try:
        await mqtt_task
    except asyncio.CancelledError:
        pass

app = FastAPI(title="Centro de Productividad IoT", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(readings.router, prefix="/api", tags=["Readings"])
app.include_router(calibration.router, prefix="/api", tags=["Calibration"])

@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "iot-backend"}
