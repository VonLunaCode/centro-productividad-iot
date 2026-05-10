from pydantic_settings import BaseSettings
from typing import Optional

class Settings(BaseSettings):
    # MQTT
    MQTT_HOST: str = "2503ca92a57b47a2860cdc3c3b9477b2.s1.eu.hivemq.cloud"
    MQTT_PORT: int = 8883
    MQTT_USER: str = "esp32-client"
    MQTT_PASS: str = "Esp32-client"
    MQTT_DEVICE_ID: str = "esp32-01"
    MQTT_TOPIC_DATA: str = "sensors/data"
    MQTT_TOPIC_CMD_PREFIX: str = "device"
    
    # Database
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/iot_db"
    
    # JWT
    JWT_SECRET: str = "secret-key-cambiar-en-prod"
    JWT_ALGORITHM: str = "HS256"
    JWT_EXPIRE_MINUTES: int = 1440
    
    # Seed de usuarios (formato: "user:pass;user:pass")
    USERS_SEED: str = "admin:admin123;estudiante:iot2024"
    
    # Alert Thresholds (Legacy - se mantendrán hasta completar migración de lógica a perfiles)
    MIN_LIGHT_RAW: int = 500
    POSTURE_THRESHOLD_MM: int = 400
    
    class Config:
        env_file = ".env"

settings = Settings()
