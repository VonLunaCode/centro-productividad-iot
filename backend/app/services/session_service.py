import logging
from ..database import fetch_one, execute_query
from ..mqtt_publisher import publish_cmd

logger = logging.getLogger(__name__)

async def get_active_session(device_id: str):
    """
    Busca la sesión activa para un dispositivo específico.
    """
    query = "SELECT * FROM sessions WHERE device_id = $1 AND ended_at IS NULL"
    row = await fetch_one(query, device_id)
    return dict(row) if row else None

async def get_active_session_by_user(user_id: int):
    """
    Busca la sesión activa para un usuario específico.
    """
    query = "SELECT * FROM sessions WHERE user_id = $1 AND ended_at IS NULL LIMIT 1"
    row = await fetch_one(query, user_id)
    return dict(row) if row else None

async def start_session(user_id: int, device_id: str, profile_id: int = None):
    """
    Crea una nueva sesión en la DB y envía el comando MQTT al ESP32.
    """
    # 1. Comprobar si ya hay una sesión activa para este dispositivo
    active = await get_active_session(device_id)
    if active:
        return None, "El dispositivo ya tiene una sesión activa"
    
    # 2. Insertar en PostgreSQL
    query = """
    INSERT INTO sessions (user_id, profile_id, device_id, started_at)
    VALUES ($1, $2, $3, NOW())
    RETURNING id, started_at
    """
    row = await fetch_one(query, user_id, profile_id, device_id)
    session_id = row["id"]
    
    # 3. Notificar al ESP32 vía MQTT
    try:
        await publish_cmd(device_id, "start", session_id)
    except Exception as e:
        logger.error(f"Fallo crítico al notificar inicio de sesión vía MQTT: {e}")
        # En una app de producción aquí podríamos decidir si hacer rollback del INSERT
    
    return dict(row), None

async def stop_session(user_id: int):
    """
    Finaliza la sesión activa del usuario.
    """
    # 1. Buscar la sesión activa del usuario
    active = await get_active_session_by_user(user_id)
    if not active:
        return None, "No tienes ninguna sesión activa para finalizar"
    
    session_id = active["id"]
    device_id = active["device_id"]
    
    # 2. Actualizar ended_at en PostgreSQL
    query = "UPDATE sessions SET ended_at = NOW() WHERE id = $1 RETURNING id, ended_at"
    row = await fetch_one(query, session_id)
    
    # 3. Notificar al ESP32 vía MQTT
    try:
        await publish_cmd(device_id, "stop", session_id)
    except Exception as e:
        logger.error(f"Fallo al notificar fin de sesión vía MQTT: {e}")
        
    return dict(row), None
