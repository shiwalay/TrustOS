import pytest
from opentelemetry.sdk.trace import TracerProvider
from pydantic import ValidationError
from trustos_core.otel import init_telemetry
from trustos_core.settings import BaseServiceSettings


class _Settings(BaseServiceSettings):
    model_config = BaseServiceSettings.model_config | {"env_prefix": "TESTSVC_"}
    service_name: str = "test-service"


def test_settings_defaults() -> None:
    settings = _Settings()
    assert settings.environment == "local"
    assert settings.region == "ap-south-1"


def test_settings_env_override(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("TESTSVC_ENVIRONMENT", "staging")
    assert _Settings().environment == "staging"


def test_settings_environment_pattern_enforced(monkeypatch: pytest.MonkeyPatch) -> None:
    monkeypatch.setenv("TESTSVC_ENVIRONMENT", "production-ish")
    with pytest.raises(ValidationError):
        _Settings()


def test_settings_frozen() -> None:
    settings = _Settings()
    with pytest.raises(ValidationError):
        settings.environment = "prod"  # type: ignore[misc]


def test_init_telemetry_returns_provider_and_is_idempotent() -> None:
    provider = init_telemetry(service_name="test-service", region="ap-south-1")
    assert isinstance(provider, TracerProvider)
    assert provider.resource.attributes["service.name"] == "test-service"
    again = init_telemetry(service_name="other")
    assert again is provider  # second call returns installed provider
