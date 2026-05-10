from fastapi import APIRouter, Depends, Query
from typing import List, Optional
from ..security import get_current_user
from ..services import reading_service

router = APIRouter(prefix="/readings", tags=["Readings"])

@router.get("/")
async def get_readings(
    device_id: Optional[str] = None, 
    limit: int = Query(50, le=500),
    current_user: dict = Depends(get_current_user)
):
    """
    Retorna el historial de lecturas de sensores.
    Solo retorna datos pertenecientes al usuario autenticado.
    """
    return await reading_service.list_readings(
        user_id=current_user["id"],
        device_id=device_id,
        limit=limit
    )
