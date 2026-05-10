import asyncio
import sys

if sys.platform == "win32":
    asyncio.set_event_loop_policy(asyncio.WindowsSelectorEventLoopPolicy())
from contextlib import asynccontextmanager
from fastapi import FastAPI, WebSocket, WebSocketDisconnect
from fastapi.middleware.cors import CORSMiddleware
from .database import init_db, close_db
from .mqtt_subscriber import run_subscriber
from .services.auth_service import seed_users
from .routes import readings, profiles, auth, sessions
from .websocket import manager

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print("API: Iniciando lifespan...")
    await init_db()
    
    print("API: Sembrando usuarios iniciales...")
    await seed_users()
    
    print("API: Base de datos inicializada. Iniciando tarea MQTT...")
    # Run MQTT subscriber in background
    mqtt_task = asyncio.create_task(run_subscriber())
    yield
    # Shutdown
    print("API: Cerrando recursos...")
    mqtt_task.cancel()
    try:
        await mqtt_task
    except asyncio.CancelledError:
        pass
    await close_db()

app = FastAPI(title="Centro de Productividad IoT", lifespan=lifespan)

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(auth.router, prefix="/api", tags=["Auth"])
app.include_router(sessions.router, prefix="/api", tags=["Sessions"])
app.include_router(readings.router, prefix="/api", tags=["Readings"])
app.include_router(profiles.router, prefix="/api", tags=["Profiles"])

@app.websocket("/ws")
async def websocket_endpoint(websocket: WebSocket):
    await manager.connect(websocket)
    try:
        while True:
            # Keep connection alive; data flows via broadcast from MQTT subscriber
            await websocket.receive_text()
    except WebSocketDisconnect:
        manager.disconnect(websocket)

@app.get("/api/health")
async def health():
    return {"status": "ok", "service": "iot-backend"}
