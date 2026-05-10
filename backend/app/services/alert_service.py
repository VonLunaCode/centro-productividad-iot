import logging

logger = logging.getLogger(__name__)

def evaluate_alerts(sensor_data: dict, profile: dict):
    """
    Función pura para evaluar alertas basadas en un perfil.
    Compara cada lectura con el rango [min, max] definido en el perfil calibrado.
    
    Retorna un diccionario de booleanos (True = ALERTA).
    """
    # Diccionario de alertas individuales
    raw_alerts = {}

    # Si no hay perfil o el perfil no está calibrado, no disparamos alertas
    if not profile or not profile.get("calibrated_at"):
        return {
            "alert_posture": False,
            "alert_temp": False,
            "alert_noise": False,
            "alert_light": False,
            "alert_humidity": False
        }

    # Mapeo sensor → prefijo de columna en profiles (5 sensores reales)
    mappings = {
        "distance_mm": "distance",
        "temperature": "temp",
        "humidity": "hum",
        "noise_peak": "noise_peak",
        "lux": "lux",
    }

    for sensor_key, profile_prefix in mappings.items():
        val = sensor_data.get(sensor_key)
        raw_alerts[profile_prefix] = False

        if val is not None:
            p_min = profile.get(f"{profile_prefix}_min")
            p_max = profile.get(f"{profile_prefix}_max")

            if p_min is not None and p_max is not None:
                if val < p_min or val > p_max:
                    raw_alerts[profile_prefix] = True

    return {
        "alert_posture": raw_alerts["distance"],
        "alert_temp": raw_alerts["temp"],
        "alert_noise": raw_alerts["noise_peak"],
        "alert_light": raw_alerts["lux"],
        "alert_humidity": raw_alerts["hum"],
    }
