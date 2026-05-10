from fastapi import APIRouter, Depends, HTTPException, status
from typing import List
from ..models import ProfileCreate, ProfileResponse, CalibrateFinishRequest
from ..security import get_current_user
from ..services import profile_service
from ..mqtt_publisher import publish_cmd

router = APIRouter(prefix="/profiles", tags=["Profiles"])

@router.get("/", response_model=List[ProfileResponse])
async def list_profiles(current_user: dict = Depends(get_current_user)):
    """Retorna todos los perfiles del usuario autenticado."""
    return await profile_service.list_profiles(current_user["id"])

@router.post("/", response_model=ProfileResponse, status_code=status.HTTP_201_CREATED)
async def create_profile(
    request: ProfileCreate, 
    current_user: dict = Depends(get_current_user)
):
    """Crea un nuevo perfil para el usuario."""
    return await profile_service.create_profile(current_user["id"], request.name)

@router.put("/{id}/activate", response_model=ProfileResponse)
async def activate_profile(id: int, current_user: dict = Depends(get_current_user)):
    """
    Marca un perfil como activo. 
    Solo puede haber un perfil activo por usuario a la vez.
    """
    profile = await profile_service.activate_profile(id, current_user["id"])
    if not profile:
        raise HTTPException(status_code=404, detail="Perfil no encontrado o no pertenece al usuario")
    return profile

@router.post("/{id}/calibrate/start")
async def start_calibration(id: int, current_user: dict = Depends(get_current_user)):
    """
    Indica que el perfil está entrando en fase de calibración.
    Esto permite a la UI mostrar un estado visual de 'calibrando'.
    """
    profile = await profile_service.get_profile(id, current_user["id"])
    if not profile:
        raise HTTPException(status_code=404, detail="Perfil no encontrado")
    
    await profile_service.set_calibrating_state(id, current_user["id"], True)
    try:
        await publish_cmd("esp32-01", "start")
    except Exception:
        pass  # No bloqueamos si MQTT falla
    return {"status": "calibrating", "message": "Iniciando recolección de muestras en el cliente..."}

@router.post("/{id}/calibrate/finish", response_model=ProfileResponse)
async def finish_calibration(
    id: int,
    current_user: dict = Depends(get_current_user)
):
    """
    Lee las últimas lecturas de la DB, calcula los umbrales estadísticos
    y los persiste en el perfil.
    """
    profile, error = await profile_service.finish_calibration(id, current_user["id"])
    try:
        await publish_cmd("esp32-01", "stop")
    except Exception:
        pass
    if error:
        await profile_service.set_calibrating_state(id, current_user["id"], False)
        raise HTTPException(status_code=400, detail=error)
    return profile

@router.delete("/{id}")
async def delete_profile(id: int, current_user: dict = Depends(get_current_user)):
    """Elimina un perfil del usuario."""
    deleted = await profile_service.delete_profile(id, current_user["id"])
    if not deleted:
        raise HTTPException(status_code=404, detail="Perfil no encontrado")
    return {"status": "deleted"}
