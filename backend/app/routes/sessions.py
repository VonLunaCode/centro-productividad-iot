from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..models import SessionStartRequest, SessionResponse, ActiveSessionResponse, SessionHistoryItem
from ..security import get_current_user
from ..services.session_service import start_session, stop_session, get_active_session_by_user, get_session_history

router = APIRouter(prefix="/session", tags=["Sessions"])

@router.post("/start", response_model=SessionResponse, status_code=status.HTTP_201_CREATED)
async def api_start_session(
    request: SessionStartRequest, 
    current_user: dict = Depends(get_current_user)
):
    """
    Inicia una sesión de trabajo para un dispositivo.
    Requiere autenticación JWT. Envía un comando MQTT de 'start' al ESP32.
    """
    result, error = await start_session(
        user_id=current_user["id"],
        device_id=request.device_id,
        profile_id=request.profile_id
    )
    
    if error:
        # 409 Conflict si ya hay una sesión activa para ese dispositivo
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail=error)
    
    return {
        "id": result["id"],
        "user_id": current_user["id"],
        "profile_id": request.profile_id,
        "device_id": request.device_id,
        "started_at": result["started_at"],
        "ended_at": None
    }

@router.post("/stop", response_model=SessionResponse)
async def api_stop_session(current_user: dict = Depends(get_current_user)):
    """
    Finaliza la sesión activa del usuario autenticado.
    Envía un comando MQTT de 'stop' al ESP32.
    """
    result, error = await stop_session(user_id=current_user["id"])
    
    if error:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=error)
    
    # Retornamos los datos básicos de la sesión finalizada
    return {
        "id": result["id"],
        "user_id": current_user["id"],
        "device_id": "unknown", # El servicio podría devolverlo si fuera necesario
        "started_at": result.get("started_at"), # Si el service lo devuelve
        "ended_at": result["ended_at"]
    }

@router.get("/history", response_model=List[SessionHistoryItem])
async def api_session_history(current_user: dict = Depends(get_current_user)):
    """Retorna el historial de sesiones finalizadas con métricas agregadas."""
    return await get_session_history(current_user["id"])

@router.get("/active", response_model=ActiveSessionResponse)
async def api_get_active_session(current_user: dict = Depends(get_current_user)):
    """
    Retorna la información de la sesión activa del usuario.
    404 si no tiene ninguna sesión abierta.
    """
    active = await get_active_session_by_user(current_user["id"])
    
    if not active:
        raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail="No tienes una sesión activa")
    
    return {
        "session_id": active["id"],
        "device_id": active["device_id"],
        "profile_id": active["profile_id"],
        "started_at": active["started_at"]
    }
