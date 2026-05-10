from pydantic import BaseModel
from typing import Optional, Dict, List
from datetime import datetime

class SensorData(BaseModel):
    distance_mm: float  # VL53L0X - postura
    temperature: float  # DHT11
    humidity: float     # DHT11
    lux: float          # LDR
    noise_peak: float   # MAX4466

class ProfileCreate(BaseModel):
    name: str

class ProfileResponse(BaseModel):
    id: int
    user_id: int
    name: str
    is_active: bool
    calibrating: bool
    
    # Umbrales y estadísticas — 5 sensores reales del hardware
    distance_min: Optional[float] = None  # VL53L0X postura
    distance_max: Optional[float] = None
    distance_mean: Optional[float] = None
    distance_std: Optional[float] = None

    temp_min: Optional[float] = None      # DHT11
    temp_max: Optional[float] = None
    temp_mean: Optional[float] = None
    temp_std: Optional[float] = None

    hum_min: Optional[float] = None       # DHT11
    hum_max: Optional[float] = None
    hum_mean: Optional[float] = None
    hum_std: Optional[float] = None

    noise_peak_min: Optional[float] = None  # MAX4466
    noise_peak_max: Optional[float] = None
    noise_peak_mean: Optional[float] = None
    noise_peak_std: Optional[float] = None

    lux_min: Optional[float] = None       # LDR
    lux_max: Optional[float] = None
    lux_mean: Optional[float] = None
    lux_std: Optional[float] = None
    
    calibrated_at: Optional[datetime] = None
    created_at: datetime
    updated_at: datetime

class CalibrateFinishRequest(BaseModel):
    samples: List[SensorData]

# Modelos para Autenticación
class LoginRequest(BaseModel):
    username: str
    password: str

class RegisterRequest(BaseModel):
    username: str
    password: str

class TokenResponse(BaseModel):
    access_token: str
    token_type: str = "bearer"

from datetime import datetime

class UserResponse(BaseModel):
    id: int
    username: str

# Modelos para Sesiones
class SessionStartRequest(BaseModel):
    device_id: str
    profile_id: Optional[int] = None

class SessionResponse(BaseModel):
    id: int
    user_id: int
    profile_id: Optional[int] = None
    device_id: str
    started_at: datetime
    ended_at: Optional[datetime] = None

class ActiveSessionResponse(BaseModel):
    session_id: int
    device_id: str
    profile_id: Optional[int] = None
    started_at: datetime
