"""pydantic-settings base for all services (03-backend-architecture.md §2.8).

12-factor: env vars only in k8s; ``.env`` for local dev. Services subclass and
set ``env_prefix`` (e.g. ``REFERRAL_``). SecretStr keeps secrets out of repr/logs.
"""

from __future__ import annotations

from pydantic import Field
from pydantic_settings import BaseSettings, SettingsConfigDict


class BaseServiceSettings(BaseSettings):
    model_config = SettingsConfigDict(env_file=".env", frozen=True, extra="ignore")

    service_name: str = "service"
    environment: str = Field(pattern="^(local|dev|staging|prod)$", default="local")
    region: str = "ap-south-1"  # cell identity (shared-context §1)
