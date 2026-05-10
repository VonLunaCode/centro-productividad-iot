import asyncpg
import logging
from .config import settings

# Configuración de logging para ver errores de DB
logger = logging.getLogger(__name__)

# Pool global para la aplicación
_pool: asyncpg.Pool = None

async def init_db():
    """
    Inicializa el pool de conexiones a PostgreSQL.
    Railway inyecta DATABASE_URL que puede empezar con postgres://,
    pero asyncpg requiere explícitamente postgresql://.
    """
    global _pool
    dsn = settings.DATABASE_URL
    if dsn.startswith("postgres://"):
        dsn = dsn.replace("postgres://", "postgresql://", 1)
    
    try:
        _pool = await asyncpg.create_pool(
            dsn=dsn,
            min_size=2,
            max_size=10,
            command_timeout=60
        )
        logger.info("Pool de conexiones a PostgreSQL inicializado correctamente.")
    except Exception as e:
        logger.error(f"Error al inicializar el pool de conexiones: {e}")
        raise e

async def close_db():
    """Cierra el pool de conexiones al apagar la aplicación."""
    global _pool
    if _pool:
        await _pool.close()
        logger.info("Pool de conexiones a PostgreSQL cerrado.")

async def get_db():
    """
    Dependency para FastAPI que provee una conexión del pool.
    Se usa como: `conn: asyncpg.Connection = Depends(get_db)`
    """
    if _pool is None:
        raise RuntimeError("El pool de base de datos no ha sido inicializado.")
    
    async with _pool.acquire() as connection:
        yield connection

# Helper para ejecutar queries fuera del contexto de una request (ej. MQTT subscriber)
async def execute_query(query: str, *args):
    """Ejecuta una query que no devuelve resultados."""
    if _pool is None:
        raise RuntimeError("Pool no inicializado")
    async with _pool.acquire() as conn:
        return await conn.execute(query, *args)

async def fetch_one(query: str, *args):
    """Ejecuta una query y devuelve una sola fila."""
    if _pool is None:
        raise RuntimeError("Pool no inicializado")
    async with _pool.acquire() as conn:
        return await conn.fetchrow(query, *args)

async def fetch_all(query: str, *args):
    """Ejecuta una query y devuelve todas las filas."""
    if _pool is None:
        raise RuntimeError("Pool no inicializado")
    async with _pool.acquire() as conn:
        return await conn.fetch(query, *args)
