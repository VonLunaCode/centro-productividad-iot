from pydantic import BaseModel
from typing import Optional, Dict

class SensorData(BaseModel):
    distance_mm: int
    temperature_c: float
    humidity_pct: float
    light_raw: int
    noise_peak: int

class Alerts(BaseModel):
    posture: bool
    low_light: bool

class SensorReading(BaseModel):
    device_id: str
    ts: int
    sensors: SensorData
    alerts: Alerts

class CalibrationData(BaseModel):
    device_id: str
    baseline_mm: int
    threshold_mm: int
    calibrated_at: Optional[str] = None

class CalibrationRequest(BaseModel):
    device_id: str
    samples: int = 10

class Profile(BaseModel):
    id: Optional[int] = None
    name: str
    threshold_mm: int = 400
    device_id: str = "esp32-01"
    is_active: bool = False
    created_at: Optional[str] = None

class ProfileCreate(BaseModel):
    name: str
    threshold_mm: int = 400
    device_id: str = "esp32-01"

class ProfileUpdate(BaseModel):
    threshold_mm: Optional[int] = None
