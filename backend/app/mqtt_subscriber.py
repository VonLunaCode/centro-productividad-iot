import json
import asyncio
import aiomqtt
import ssl
import logging
from .config import settings
from .database import fetch_one, execute_query
from .services.alert_service import evaluate_alerts

logger = logging.getLogger(__name__)

async def run_subscriber():
    """
    Bucle principal del suscriptor MQTT.
    Mantiene la conexión con HiveMQ y procesa las lecturas entrantes.
    """
    context = ssl.create_default_context()
    interval = 1 
    
    while True:
        try:
            logger.info(f"MQTT: Conectando a {settings.MQTT_HOST}:{settings.MQTT_PORT}...")
            async with aiomqtt.Client(
                hostname=settings.MQTT_HOST,
                port=settings.MQTT_PORT,
                username=settings.MQTT_USER,
                password=settings.MQTT_PASS,
                tls_context=context
            ) as client:
                logger.info("MQTT: ¡CONECTADO! Suscribiendo a telemetría...")
                # Suscribimos a lecturas de sensores de cualquier dispositivo bajo el prefijo
                await client.subscribe("centro-productividad/+/sensors")
                await client.subscribe("centro-productividad/+/status")

                async for message in client.messages:
                    try:
                        topic = str(message.topic)
                        payload = message.payload.decode()
                        if topic.endswith("/status"):
                            await process_status(topic, payload)
                        else:
                            data = json.loads(payload)
                            await process_reading(data)
                    except Exception as e:
                        logger.error(f"MQTT: Error al procesar mensaje en {message.topic}: {e}")
                             
        except Exception as error:
            logger.error(f"MQTT Error Fatal: {error}. Reintentando en {interval}s...")
            await asyncio.sleep(interval)
            interval = min(interval * 2, 60)

async def process_status(topic: str, status: str):
    parts = topic.split("/")
    device_id = parts[1] if len(parts) >= 3 else "unknown"
    from .websocket import manager
    await manager.broadcast(json.dumps({
        "type": "device_status",
        "device_id": device_id,
        "status": status.strip(),
    }))
    logger.info(f"MQTT: Estado de {device_id} -> {status}")

async def process_reading(data):
    """
    Procesa una lectura individual:
    1. Identifica sesión/usuario/perfil activo.
    2. Evalúa alertas basadas en el perfil.
    3. Persiste en PostgreSQL.
    4. Notifica vía WebSocket.
    """
    device_id = data.get("device_id")
    sensors = data.get("sensors", {})
    
    if not device_id:
        logger.warning("MQTT: Recibida lectura sin device_id. Ignorando.")
        return

    # 1. Buscar sesión activa para el dispositivo (para asociar user_id y profile_id)
    session = await fetch_one(
        "SELECT id, user_id, profile_id FROM sessions WHERE device_id = $1 AND ended_at IS NULL",
        device_id
    )
    
    profile = None
    if session and session["profile_id"]:
        # Traemos el perfil completo para evaluar los umbrales
        profile = await fetch_one("SELECT * FROM profiles WHERE id = $1", session["profile_id"])

    # 2. Evaluar alertas (Función pura)
    alerts = evaluate_alerts(sensors, profile)
    
    # 3. Guardar en PostgreSQL (usando pool de asyncpg)
    query = """
    INSERT INTO readings (
        session_id, user_id, profile_id, device_id,
        distance_mm, temperature, humidity, lux, noise_peak,
        alert_posture, alert_temp, alert_noise, alert_light, alert_humidity
    ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14)
    """

    try:
        await execute_query(
            query,
            session["id"] if session else None,
            session["user_id"] if session else None,
            session["profile_id"] if session else None,
            device_id,
            sensors.get("distance_mm"),
            sensors.get("temperature"),
            sensors.get("humidity"),
            sensors.get("lux"),
            sensors.get("noise_peak"),
            alerts["alert_posture"],
            alerts["alert_temp"],
            alerts["alert_noise"],
            alerts["alert_light"],
            alerts["alert_humidity"]
        )
        logger.debug(f"DB: Lectura guardada para {device_id}")
    except Exception as e:
        logger.error(f"DB Error: No se pudo guardar la lectura de {device_id}: {e}")

    # 4. Broadcast vía WebSocket (Notificación en tiempo real)
    from .websocket import manager
    ws_payload = {
        "type": "sensor_update",
        "device_id": device_id,
        "sensors": sensors,
        "alerts": alerts,
        "session_active": session is not None
    }
    await manager.broadcast(json.dumps(ws_payload))
