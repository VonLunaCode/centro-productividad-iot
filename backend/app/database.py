import aiosqlite
import os
from .config import settings

DB_PATH = settings.DATABASE_URL.replace("sqlite:///", "")

async def init_db():
    # Ensure directory exists
    os.makedirs(os.path.dirname(DB_PATH), exist_ok=True)
    
    async with aiosqlite.connect(DB_PATH) as db:
        await db.execute("PRAGMA journal_mode=WAL")
        
        # Readings table
        await db.execute("""
            CREATE TABLE IF NOT EXISTS readings (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id TEXT NOT NULL,
                ts INTEGER NOT NULL,
                distance_mm INTEGER,
                temperature_c REAL,
                humidity_pct REAL,
                light_raw INTEGER,
                noise_peak INTEGER,
                posture_alert BOOLEAN,
                low_light_alert BOOLEAN,
                created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Calibration table
        await db.execute("""
            CREATE TABLE IF NOT EXISTS calibration (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                device_id TEXT NOT NULL,
                baseline_mm INTEGER NOT NULL,
                threshold_mm INTEGER NOT NULL,
                calibrated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
            )
        """)
        
        # Index for performance
        await db.execute("CREATE INDEX IF NOT EXISTS idx_readings_device_ts ON readings (device_id, ts DESC)")
        
        await db.commit()

async def get_db():
    db = await aiosqlite.connect(DB_PATH)
    db.row_factory = aiosqlite.Row
    try:
        yield db
    finally:
        await db.close()
