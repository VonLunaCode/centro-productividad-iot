from fastapi import APIRouter, Depends, HTTPException
import aiomqtt
import ssl
import json
from ..config import settings
from ..database import get_db
from ..models import CalibrationRequest
import aiosqlite

router = APIRouter()

@router.post("/calibrate")
async def calibrate_device(req: CalibrationRequest):
    # 1. Publish start command to MQTT
    context = ssl.create_default_context()
    try:
        async with aiomqtt.Client(
            hostname=settings.MQTT_HOST,
            port=settings.MQTT_PORT,
            username=settings.MQTT_USER,
            password=settings.MQTT_PASS,
            tls_context=context
        ) as client:
            payload = json.dumps({"command": "start", "samples": req.samples})
            await client.publish(f"centro-productividad/{req.device_id}/calibrate", payload)
            
            return {"status": "command_sent", "device_id": req.device_id}
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Failed to send MQTT command: {e}")

@router.get("/calibration/{device_id}")
async def get_calibration(device_id: str, db: aiosqlite.Connection = Depends(get_db)):
    cursor = await db.execute(
        "SELECT * FROM calibration WHERE device_id = ? ORDER BY id DESC LIMIT 1",
        (device_id,)
    )
    row = await cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Calibration not found")
    return dict(row)
