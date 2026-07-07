"""pydantic-settings (03 §2.8). 12-factor: env vars in k8s; .env for local dev."""

from __future__ import annotations

from pydantic_settings import SettingsConfigDict
from trustos_core.settings import BaseServiceSettings


class Settings(BaseServiceSettings):
    model_config = SettingsConfigDict(env_prefix="REFERRAL_", env_file=".env", frozen=True, extra="ignore")

    service_name: str = "referral-service"

    database_url: str = "postgresql+asyncpg://trustos:trustos@localhost:5432/referral"
    db_pool_size: int = 10
    redis_url: str = "redis://localhost:6379/0"
    kafka_bootstrap: str = "localhost:9092"
    temporal_address: str = "localhost:7233"
    temporal_namespace: str = "referral"
    cursor_secret: str = "dev-only-cursor-secret-change-me"
    # dev stand-in for the trust-service band lookup (infrastructure/gateways/trust.py)
    trust_band_default: str = "silver"
    otlp_endpoint: str | None = None
