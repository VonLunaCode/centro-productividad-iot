from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    MQTT_HOST: str = "2503ca92a57b47a2860cdc3c3b9477b2.s1.eu.hivemq.cloud"
    MQTT_PORT: int = 8883
    MQTT_USER: str = "esp32-client"
    MQTT_PASS: str = "Esp32-client"
    MQTT_DEVICE_ID: str = "esp32-01"
    
    DATABASE_URL: str = "sqlite:///data/readings.db"
    
    # Alert Thresholds (Defaults)
    MIN_LIGHT_RAW: int = 500
    POSTURE_THRESHOLD_MM: int = 400
    
    class Config:
        env_file = ".env"

settings = Settings()
