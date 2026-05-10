import json
import ssl
import aiomqtt
import logging
from .config import settings

logger = logging.getLogger(__name__)

async def publish_cmd(device_id: str, action: str, session_id: int):
    """
    Publica un comando al dispositivo vía MQTT.
    
    Topic: device/{device_id}/cmd
    Payload: {"action": "start"|"stop", "session_id": N}
    
    Nota: El ESP32 debe estar suscrito a este tópico para reaccionar.
    """
    topic = f"{settings.MQTT_TOPIC_CMD_PREFIX}/{device_id}/cmd"
    payload = {
        "action": action,
        "session_id": session_id
    }
    
    # Contexto TLS para HiveMQ Cloud
    context = ssl.create_default_context()
    
    try:
        async with aiomqtt.Client(
            hostname=settings.MQTT_HOST,
            port=settings.MQTT_PORT,
            username=settings.MQTT_USER,
            password=settings.MQTT_PASS,
            tls_context=context
        ) as client:
            await client.publish(topic, payload=json.dumps(payload), qos=1)
            logger.info(f"MQTT: Comando '{action}' enviado exitosamente a {topic}")
    except Exception as e:
        logger.error(f"MQTT Error: No se pudo enviar el comando '{action}' a {device_id}: {e}")
        # No relanzamos la excepción para evitar que el endpoint 500 si el broker está caído,
        # pero el registro en DB ya se hizo. Depende de la política de reintentos deseada.
        raise e
