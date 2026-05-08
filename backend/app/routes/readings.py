from fastapi import APIRouter, Depends, Query
from typing import List
from ..database import get_db
from ..models import SensorReading
import aiosqlite

router = APIRouter()

@router.get("/readings")
async def get_readings(
    device_id: str = None, 
    limit: int = 50,
    db: aiosqlite.Connection = Depends(get_db)
):
    query = "SELECT * FROM readings"
    params = []
    if device_id:
        query += " WHERE device_id = ?"
        params.append(device_id)
    
    query += " ORDER BY ts DESC LIMIT ?"
    params.append(limit)
    
    cursor = await db.execute(query, params)
    rows = await cursor.fetchall()
    return [dict(row) for row in rows]
