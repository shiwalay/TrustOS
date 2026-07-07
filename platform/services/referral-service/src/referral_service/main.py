"""HTTP entrypoint: create_app() — FastAPI + composition root + middleware (03 §2.7).

Run locally:  uv run uvicorn --factory referral_service.main:create_app --reload
"""

from __future__ import annotations

from fastapi import FastAPI
from trustos_core.idempotency import IdempotencyMiddleware
from trustos_core.otel import init_telemetry
from trustos_core.problems import install_problem_details

from referral_service.api.http.errors import install_error_mapping
from referral_service.api.http.routers import internal, referrals
from referral_service.di import Container, build_container


def create_app(container: Container | None = None) -> FastAPI:
    container = container or build_container()
    settings = container.settings
    init_telemetry(
        service_name=settings.service_name,
        otlp_endpoint=settings.otlp_endpoint,
        region=settings.region,
        environment=settings.environment,
    )

    app = FastAPI(title="referral-service", version="1.0.0")
    app.state.container = container
    install_problem_details(app)   # RFC 9457 handlers (03 §4.2)
    install_error_mapping(app)     # domain/application errors -> problem catalog
    app.add_middleware(IdempotencyMiddleware, backend=container.idempotency_backend)
    app.include_router(referrals.router)
    app.include_router(internal.router)
    return app
