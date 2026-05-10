"""initial_schema

Revision ID: 81883eb27126
Revises: 
Create Date: 2026-05-09 14:01:41.223847

"""
from typing import Sequence, Union

from alembic import op
import sqlalchemy as sa


# revision identifiers, used by Alembic.
revision: str = '81883eb27126'
down_revision: Union[str, None] = None
branch_labels: Union[str, Sequence[str], None] = None
depends_on: Union[str, Sequence[str], None] = None


def upgrade() -> None:
    # 1. Tabla de Usuarios
    op.execute("""
    CREATE TABLE users (
        id              SERIAL PRIMARY KEY,
        username        VARCHAR(64) NOT NULL UNIQUE,
        password_hash   TEXT NOT NULL,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    """)

    # 2. Tabla de Perfiles (Umbrales estadísticos)
    op.execute("""
    CREATE TABLE profiles (
        id              SERIAL PRIMARY KEY,
        user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        name            VARCHAR(128) NOT NULL,
        is_active       BOOLEAN NOT NULL DEFAULT FALSE,
        calibrating     BOOLEAN NOT NULL DEFAULT FALSE,

        -- Umbrales mean ± 2σ — 5 sensores reales del hardware
        distance_min    REAL, distance_max    REAL, distance_mean    REAL, distance_std    REAL,
        temp_min        REAL, temp_max        REAL, temp_mean        REAL, temp_std        REAL,
        hum_min         REAL, hum_max         REAL, hum_mean         REAL, hum_std         REAL,
        noise_peak_min  REAL, noise_peak_max  REAL, noise_peak_mean  REAL, noise_peak_std  REAL,
        lux_min         REAL, lux_max         REAL, lux_mean         REAL, lux_std         REAL,

        calibrated_at   TIMESTAMPTZ,
        created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
    );
    """)
    op.execute("CREATE INDEX idx_profiles_user_active ON profiles(user_id, is_active);")
    op.execute("CREATE UNIQUE INDEX uniq_active_profile_per_user ON profiles(user_id) WHERE is_active = TRUE;")

    # 3. Tabla de Sesiones (Controladas por MQTT)
    op.execute("""
    CREATE TABLE sessions (
        id              SERIAL PRIMARY KEY,
        user_id         INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        profile_id      INTEGER REFERENCES profiles(id) ON DELETE SET NULL,
        device_id       VARCHAR(64) NOT NULL,
        started_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
        ended_at        TIMESTAMPTZ,
        notes           TEXT
    );
    """)
    op.execute("CREATE INDEX idx_sessions_user_started ON sessions(user_id, started_at DESC);")
    op.execute("CREATE INDEX idx_sessions_active ON sessions(device_id) WHERE ended_at IS NULL;")

    # 4. Tabla de Lecturas (Ingesta de telemetría)
    op.execute("""
    CREATE TABLE readings (
        id              BIGSERIAL PRIMARY KEY,
        session_id      INTEGER REFERENCES sessions(id) ON DELETE SET NULL,
        user_id         INTEGER REFERENCES users(id)    ON DELETE SET NULL,
        profile_id      INTEGER REFERENCES profiles(id) ON DELETE SET NULL,
        device_id       VARCHAR(64) NOT NULL,
        ts              TIMESTAMPTZ NOT NULL DEFAULT NOW(),

        -- 5 sensores reales: VL53L0X, DHT11 x2, LDR, MAX4466
        distance_mm     REAL,
        temperature     REAL,
        humidity        REAL,
        lux             REAL,
        noise_peak      REAL,

        -- Banderas de alerta (evaluadas en el ingest)
        alert_posture   BOOLEAN NOT NULL DEFAULT FALSE,
        alert_temp      BOOLEAN NOT NULL DEFAULT FALSE,
        alert_noise     BOOLEAN NOT NULL DEFAULT FALSE,
        alert_light     BOOLEAN NOT NULL DEFAULT FALSE,
        alert_humidity  BOOLEAN NOT NULL DEFAULT FALSE
    );
    """)
    op.execute("CREATE INDEX idx_readings_user_ts ON readings(user_id, ts DESC);")
    op.execute("CREATE INDEX idx_readings_session_ts ON readings(session_id, ts DESC);")
    op.execute("CREATE INDEX idx_readings_device_ts ON readings(device_id, ts DESC);")
    op.execute("""
    CREATE INDEX idx_readings_any_alert ON readings(session_id, ts DESC)
    WHERE alert_posture OR alert_temp OR alert_noise OR alert_light OR alert_humidity;
    """)


def downgrade() -> None:
    op.execute("DROP TABLE readings CASCADE;")
    op.execute("DROP TABLE sessions CASCADE;")
    op.execute("DROP TABLE profiles CASCADE;")
    op.execute("DROP TABLE users CASCADE;")
