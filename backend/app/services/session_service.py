import logging
from ..database import fetch_one, fetch_all, execute_query
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
    # 1. Cerrar cualquier sesión colgada para este dispositivo
    active = await get_active_session(device_id)
    if active:
        await execute_query(
            "UPDATE sessions SET ended_at = NOW() WHERE id = $1",
            active["id"]
        )
        logger.info(f"Sesión colgada {active['id']} cerrada automáticamente al iniciar nueva.")
    
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

async def get_session_history(user_id: int, limit: int = 20):
    rows = await fetch_all(
        """
        SELECT
            s.id,
            s.started_at,
            s.ended_at,
            EXTRACT(EPOCH FROM (s.ended_at - s.started_at)) / 60 AS duration_minutes,
            p.name AS profile_name,
            COUNT(r.id) AS total_readings,
            ROUND(AVG(CASE WHEN r.alert_posture THEN 1.0 ELSE 0.0 END) * 100, 1) AS posture_alert_pct,
            ROUND(AVG(CASE WHEN r.alert_temp    THEN 1.0 ELSE 0.0 END) * 100, 1) AS temp_alert_pct,
            ROUND(AVG(CASE WHEN r.alert_noise   THEN 1.0 ELSE 0.0 END) * 100, 1) AS noise_alert_pct,
            ROUND(AVG(CASE WHEN r.alert_light   THEN 1.0 ELSE 0.0 END) * 100, 1) AS light_alert_pct,
            ROUND(AVG(CASE WHEN r.alert_humidity THEN 1.0 ELSE 0.0 END) * 100, 1) AS humidity_alert_pct
        FROM sessions s
        LEFT JOIN profiles p ON p.id = s.profile_id
        LEFT JOIN readings r ON r.session_id = s.id
        WHERE s.user_id = $1 AND s.ended_at IS NOT NULL
        GROUP BY s.id, s.started_at, s.ended_at, p.name
        ORDER BY s.started_at DESC
        LIMIT $2
        """,
        user_id, limit
    )
    return [dict(r) for r in rows]

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
    query = "UPDATE sessions SET ended_at = NOW() WHERE id = $1 RETURNING id, started_at, ended_at"
    row = await fetch_one(query, session_id)
    
    # 3. Notificar al ESP32 vía MQTT
    try:
        await publish_cmd(device_id, "stop", session_id)
    except Exception as e:
        logger.error(f"Fallo al notificar fin de sesión vía MQTT: {e}")
        
    return dict(row), None
