from ..database import fetch_all

async def list_readings(user_id: int, device_id: str = None, limit: int = 50):
    """
    Lista las últimas lecturas filtrando por usuario.
    Opcionalmente filtra por dispositivo.
    """
    query = "SELECT * FROM readings WHERE user_id = $1"
    params = [user_id]
    
    param_idx = 2
    if device_id:
        query += f" AND device_id = ${param_idx}"
        params.append(device_id)
        param_idx += 1
        
    query += f" ORDER BY ts DESC LIMIT ${param_idx}"
    params.append(limit)
    
    return await fetch_all(query, *params)
