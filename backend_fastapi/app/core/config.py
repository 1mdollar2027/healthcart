"""
HealthCart Backend – Configuration
All settings loaded from environment variables via Pydantic Settings.
"""
from pydantic_settings import BaseSettings
from functools import lru_cache


class Settings(BaseSettings):
    # ── App ──
    APP_NAME: str = "HealthCart API"
    APP_VERSION: str = "1.0.0"
    DEBUG: bool = False
    API_PREFIX: str = "/api/v1"
    CORS_ORIGINS: list[str] = ["*"]

    # ── Supabase ──
    SUPABASE_URL: str = ""
    SUPABASE_ANON_KEY: str = ""
    SUPABASE_SERVICE_ROLE_KEY: str = ""
    SUPABASE_JWT_SECRET: str = ""

    # ── Database (direct connection for admin ops) ──
    DATABASE_URL: str = "postgresql://postgres:postgres@localhost:5432/healthcart"

    # ── Razorpay ──
    RAZORPAY_KEY_ID: str = ""
    RAZORPAY_KEY_SECRET: str = ""
    RAZORPAY_WEBHOOK_SECRET: str = ""

    # ── Agora ──
    AGORA_APP_ID: str = ""
    AGORA_APP_CERTIFICATE: str = ""

    # ── Firebase (FCM) ──
    FIREBASE_CREDENTIALS_PATH: str = ""

    # ── MSG91 (SMS/OTP) ──
    MSG91_AUTH_KEY: str = ""
    MSG91_TEMPLATE_ID: str = ""
    MSG91_SENDER_ID: str = "HCART"

    # ── MQTT (EMQX) ──
    MQTT_BROKER_HOST: str = "localhost"
    MQTT_BROKER_PORT: int = 1883
    MQTT_USERNAME: str = ""
    MQTT_PASSWORD: str = ""

    # ── Security ──
    JWT_ALGORITHM: str = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES: int = 60
    REFRESH_TOKEN_EXPIRE_DAYS: int = 30

    # ── Rate Limiting ──
    RATE_LIMIT: str = "100/minute"

    # ── Storage ──
    PRESCRIPTION_BUCKET: str = "prescriptions"
    LAB_RESULTS_BUCKET: str = "lab-results"
    AVATARS_BUCKET: str = "avatars"

    model_config = {"env_file": ".env", "env_file_encoding": "utf-8", "extra": "ignore"}


@lru_cache()
def get_settings() -> Settings:
    return Settings()
