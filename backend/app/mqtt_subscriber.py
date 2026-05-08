import json
import asyncio
import aiomqtt
import ssl
import aiosqlite
from .config import settings
from .database import DB_PATH
from .models import SensorReading

async def run_subscriber():
    # TLS Context for HiveMQ Cloud
    context = ssl.create_default_context()
    
    interval = 1 # retry interval
    
    while True:
        try:
            print(f"MQTT: Conectando a {settings.MQTT_HOST}:{settings.MQTT_PORT}...")
            async with aiomqtt.Client(
                hostname=settings.MQTT_HOST,
                port=settings.MQTT_PORT,
                username=settings.MQTT_USER,
                password=settings.MQTT_PASS,
                tls_context=context
            ) as client:
                print(f"MQTT: ¡CONECTADO! Suscribiendo a centro-productividad/+/sensors")
                await client.subscribe("centro-productividad/+/sensors")
                print(f"MQTT: Suscripto a centro-productividad/+/sensors")
                async for message in client.messages:
                    print(f"MQTT: Mensaje recibido en {message.topic}")
                    payload = message.payload.decode()
                    print(f"MQTT: Payload: {payload}")
                    try:
                        data = json.loads(payload)
                        await process_reading(data)
                    except Exception as e:
                        print(f"MQTT Error: Fallo al procesar json: {e}")
                            
        except Exception as error:
            print(f"MQTT Error Fatal: {type(error).__name__}: {error}")
            print(f"Reintentando en {interval}s...")
            await asyncio.sleep(interval)
            interval = min(interval * 2, 60)

async def process_reading(data):
    # Evaluation logic
    async with aiosqlite.connect(DB_PATH) as db:
        # Get latest calibration for this device
        cursor = await db.execute(
            "SELECT threshold_mm FROM calibration WHERE device_id = ? ORDER BY id DESC LIMIT 1",
            (data['device_id'],)
        )
        row = await cursor.fetchone()
        threshold = row[0] if row else settings.POSTURE_THRESHOLD_MM
        
        # Evaluate alerts
        posture_alert = False
        if data['sensors']['distance_mm'] > 0 and data['sensors']['distance_mm'] < threshold:
            posture_alert = True
            
        low_light_alert = data['sensors']['light_raw'] < settings.MIN_LIGHT_RAW
        
        # Store in DB
        await db.execute("""
            INSERT INTO readings 
            (device_id, ts, distance_mm, temperature_c, humidity_pct, light_raw, noise_peak, posture_alert, low_light_alert)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
        """, (
            data['device_id'], data['ts'], 
            data['sensors']['distance_mm'], data['sensors']['temperature_c'], 
            data['sensors']['humidity_pct'], data['sensors']['light_raw'], 
            data['sensors']['noise_peak'], posture_alert, low_light_alert
        ))
        await db.commit()
        print(f"DB: Guardada lectura de {data['device_id']} | Postura: {posture_alert}")
        
        # Broadcast to WebSocket would happen here
