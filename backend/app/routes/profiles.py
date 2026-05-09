from fastapi import APIRouter, Depends, HTTPException
from ..database import get_db
from ..models import ProfileCreate, ProfileUpdate
import aiosqlite

router = APIRouter()

@router.get("/profiles")
async def list_profiles(db: aiosqlite.Connection = Depends(get_db)):
    cursor = await db.execute("SELECT * FROM profiles ORDER BY id ASC")
    rows = await cursor.fetchall()
    return [dict(row) for row in rows]

@router.get("/profiles/active")
async def get_active_profile(db: aiosqlite.Connection = Depends(get_db)):
    cursor = await db.execute(
        "SELECT * FROM profiles WHERE is_active = 1 LIMIT 1"
    )
    row = await cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="No active profile")
    return dict(row)

@router.post("/profiles", status_code=201)
async def create_profile(profile: ProfileCreate, db: aiosqlite.Connection = Depends(get_db)):
    try:
        cursor = await db.execute(
            "INSERT INTO profiles (name, threshold_mm, device_id) VALUES (?, ?, ?)",
            (profile.name, profile.threshold_mm, profile.device_id)
        )
        await db.commit()
        new_id = cursor.lastrowid
        cursor = await db.execute("SELECT * FROM profiles WHERE id = ?", (new_id,))
        row = await cursor.fetchone()
        return dict(row)
    except aiosqlite.IntegrityError:
        raise HTTPException(status_code=409, detail="Profile name already exists")

@router.put("/profiles/{profile_id}/activate")
async def activate_profile(profile_id: int, db: aiosqlite.Connection = Depends(get_db)):
    # Check profile exists
    cursor = await db.execute("SELECT id FROM profiles WHERE id = ?", (profile_id,))
    if not await cursor.fetchone():
        raise HTTPException(status_code=404, detail="Profile not found")
    
    # Deactivate all, activate selected
    await db.execute("UPDATE profiles SET is_active = 0")
    await db.execute("UPDATE profiles SET is_active = 1 WHERE id = ?", (profile_id,))
    await db.commit()
    
    cursor = await db.execute("SELECT * FROM profiles WHERE id = ?", (profile_id,))
    return dict(await cursor.fetchone())

@router.put("/profiles/{profile_id}/calibrate")
async def calibrate_profile(profile_id: int, db: aiosqlite.Connection = Depends(get_db)):
    """
    Toma la última lectura de distancia de la DB y la usa como nuevo threshold del perfil.
    Flutter llama a este endpoint después de que el usuario se posiciona cómodamente.
    """
    # Get latest reading distance
    cursor = await db.execute(
        "SELECT distance_mm FROM readings WHERE distance_mm > 0 ORDER BY ts DESC LIMIT 1"
    )
    row = await cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="No readings available to calibrate from")
    
    new_threshold = row[0]
    
    # Update profile threshold
    cursor = await db.execute("SELECT id FROM profiles WHERE id = ?", (profile_id,))
    if not await cursor.fetchone():
        raise HTTPException(status_code=404, detail="Profile not found")
    
    await db.execute(
        "UPDATE profiles SET threshold_mm = ? WHERE id = ?",
        (new_threshold, profile_id)
    )
    await db.commit()
    
    cursor = await db.execute("SELECT * FROM profiles WHERE id = ?", (profile_id,))
    return dict(await cursor.fetchone())

@router.delete("/profiles/{profile_id}", status_code=204)
async def delete_profile(profile_id: int, db: aiosqlite.Connection = Depends(get_db)):
    cursor = await db.execute("SELECT id, is_active FROM profiles WHERE id = ?", (profile_id,))
    row = await cursor.fetchone()
    if not row:
        raise HTTPException(status_code=404, detail="Profile not found")
    if dict(row)["is_active"]:
        raise HTTPException(status_code=400, detail="Cannot delete active profile")
    await db.execute("DELETE FROM profiles WHERE id = ?", (profile_id,))
    await db.commit()
