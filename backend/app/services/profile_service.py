import statistics
import logging
from ..database import fetch_one, fetch_all, execute_query

logger = logging.getLogger(__name__)

async def list_profiles(user_id: int):
    """Lista todos los perfiles del usuario."""
    query = "SELECT * FROM profiles WHERE user_id = $1 ORDER BY created_at DESC"
    rows = await fetch_all(query, user_id)
    return [dict(r) for r in rows]

async def create_profile(user_id: int, name: str):
    """Crea un nuevo perfil vacío."""
    query = "INSERT INTO profiles (user_id, name) VALUES ($1, $2) RETURNING *"
    row = await fetch_one(query, user_id, name)
    return dict(row) if row else None

async def get_profile(profile_id: int, user_id: int):
    """Obtiene un perfil específico verificando pertenencia."""
    query = "SELECT * FROM profiles WHERE id = $1 AND user_id = $2"
    row = await fetch_one(query, profile_id, user_id)
    return dict(row) if row else None

async def activate_profile(profile_id: int, user_id: int):
    """Activa un perfil y desactiva los demás del mismo usuario."""
    await execute_query("UPDATE profiles SET is_active = FALSE WHERE user_id = $1", user_id)
    query = "UPDATE profiles SET is_active = TRUE WHERE id = $1 AND user_id = $2 RETURNING *"
    row = await fetch_one(query, profile_id, user_id)
    return dict(row) if row else None

async def delete_profile(profile_id: int, user_id: int):
    """Elimina un perfil."""
    query = "DELETE FROM profiles WHERE id = $1 AND user_id = $2 RETURNING id"
    row = await fetch_one(query, profile_id, user_id)
    return dict(row) if row else None

async def update_thresholds(profile_id: int, user_id: int, fields: dict):
    """Actualiza solo los campos de umbral que se envíen (PATCH parcial)."""
    if not fields:
        return None
    clauses = ", ".join(f"{k} = ${i+3}" for i, k in enumerate(fields))
    values = list(fields.values())
    query = f"UPDATE profiles SET {clauses}, updated_at = NOW() WHERE id = $1 AND user_id = $2 RETURNING *"
    row = await fetch_one(query, profile_id, user_id, *values)
    return dict(row) if row else None

async def set_calibrating_state(profile_id: int, user_id: int, state: bool):
    """Cambia el flag de 'calibrating' en la DB."""
    query = "UPDATE profiles SET calibrating = $1 WHERE id = $2 AND user_id = $3"
    await execute_query(query, state, profile_id, user_id)

async def finish_calibration(profile_id: int, user_id: int, device_id: str = "esp32-01"):
    """
    Lee las lecturas de los últimos 60 segundos desde la DB y calcula umbrales estadísticos.
    No depende de que el cliente mande muestras por WebSocket.
    """
    rows = await fetch_all(
        """
        SELECT distance_mm, temperature, humidity, lux, noise_peak
        FROM readings
        WHERE device_id = $1 AND ts >= NOW() - INTERVAL '60 seconds'
        ORDER BY ts DESC
        """,
        device_id,
    )

    if not rows or len(rows) < 5:
        return None, f"Se requieren al menos 5 muestras. Solo se recibieron {len(rows) if rows else 0}. Verificá que el ESP32 esté enviando datos."

    col_map = {
        "distance_mm": "distance",
        "temperature": "temp",
        "humidity": "hum",
        "noise_peak": "noise_peak",
        "lux": "lux",
    }

    update_clauses = []
    query_params = [profile_id, user_id]
    current_idx = 3

    for sensor, prefix in col_map.items():
        values = [float(r[sensor]) for r in rows if r[sensor] is not None]
        if not values:
            continue
        mean = statistics.mean(values)
        std = max(statistics.stdev(values) if len(values) > 1 else 0.1, 0.05)

        update_clauses.append(f"{prefix}_mean = ${current_idx}")
        update_clauses.append(f"{prefix}_std = ${current_idx + 1}")
        update_clauses.append(f"{prefix}_min = ${current_idx + 2}")
        update_clauses.append(f"{prefix}_max = ${current_idx + 3}")
        query_params.extend([mean, std, mean - 2 * std, mean + 2 * std])
        current_idx += 4

    query = f"""
    UPDATE profiles
    SET {", ".join(update_clauses)}, calibrating = FALSE, calibrated_at = NOW(), updated_at = NOW()
    WHERE id = $1 AND user_id = $2
    RETURNING *
    """

    try:
        row = await fetch_one(query, *query_params)
        logger.info(f"Calibración completada con {len(rows)} muestras para perfil {profile_id}")
        return (dict(row) if row else None), None
    except Exception as e:
        logger.error(f"Error al guardar calibración: {e}")
        return None, "Error interno al guardar la calibración."
