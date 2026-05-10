import logging
from ..database import fetch_one, execute_query
from ..security import hash_password, verify_password
from ..config import settings

logger = logging.getLogger(__name__)

async def seed_users():
    """
    Inserta los usuarios definidos en la configuración (USERS_SEED) si no existen.
    Es una operación idempotente que se ejecuta al inicio de la aplicación.
    """
    if not settings.USERS_SEED:
        logger.warning("No se detectó USERS_SEED en la configuración.")
        return

    users_entries = settings.USERS_SEED.split(";")
    for entry in users_entries:
        if ":" not in entry:
            continue
            
        username, password = entry.split(":", 1)
        
        # Comprobar si el usuario ya existe
        existing_user = await fetch_one("SELECT id FROM users WHERE username = $1", username)
        
        if not existing_user:
            logger.info(f"Sembrando usuario: {username}")
            hashed_pw = hash_password(password)
            await execute_query(
                "INSERT INTO users (username, password_hash) VALUES ($1, $2)",
                username, hashed_pw
            )
        else:
            logger.debug(f"El usuario {username} ya existe en la base de datos.")

async def register_user(username: str, password: str):
    """
    Crea un nuevo usuario. Retorna el usuario creado o None si el username ya existe.
    """
    existing = await fetch_one("SELECT id FROM users WHERE username = $1", username)
    if existing:
        return None

    hashed_pw = hash_password(password)
    user = await fetch_one(
        "INSERT INTO users (username, password_hash) VALUES ($1, $2) RETURNING id, username",
        username, hashed_pw
    )
    return {"id": user["id"], "username": user["username"]}

async def authenticate_user(username: str, password: str):
    """
    Verifica las credenciales de un usuario.
    Retorna el usuario si es válido, de lo contrario None.
    """
    user = await fetch_one(
        "SELECT id, username, password_hash FROM users WHERE username = $1", 
        username
    )
    
    if not user:
        return None
        
    if verify_password(user["password_hash"], password):
        # Retornamos el usuario sin el hash de la contraseña por seguridad
        return {"id": user["id"], "username": user["username"]}
        
    return None
