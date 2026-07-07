"""Map domain/application errors to the Problem Details catalog (04 §2.1)."""

from __future__ import annotations

from fastapi import FastAPI, Request
from starlette.responses import JSONResponse
from trustos_core.pagination import InvalidCursorError
from trustos_core.problems import Problem, problem_response

from referral_service.application.errors import CampaignNotFound, DuplicateReferral, ReferralNotFound
from referral_service.domain.errors import (
    InsufficientTrustBand,
    InvalidReferralTransition,
    ReferralWindowClosed,
)
from referral_service.infrastructure.db.referral_repository import StaleAggregateError


def install_error_mapping(app: FastAPI) -> None:
    def _respond(request: Request, problem: Problem) -> JSONResponse:
        return problem_response(problem, instance=request.url.path)

    @app.exception_handler(CampaignNotFound)
    async def _campaign_not_found(request: Request, exc: CampaignNotFound) -> JSONResponse:
        return _respond(request, Problem(str(exc), slug="not-found", status=404))

    @app.exception_handler(ReferralNotFound)
    async def _referral_not_found(request: Request, exc: ReferralNotFound) -> JSONResponse:
        return _respond(request, Problem(str(exc), slug="not-found", status=404))

    @app.exception_handler(ReferralWindowClosed)
    async def _window_closed(request: Request, exc: ReferralWindowClosed) -> JSONResponse:
        # campaign closed/unpublished => 404 not-found (04 §4.2 errors; no existence oracle)
        return _respond(request, Problem(str(exc), slug="not-found", status=404))

    @app.exception_handler(DuplicateReferral)
    async def _duplicate(request: Request, exc: DuplicateReferral) -> JSONResponse:
        return _respond(
            request,
            Problem(
                str(exc),
                slug="duplicate-referral",
                status=409,
                title="Duplicate referral",
                existingReferralId=exc.existing_referral_id,
            ),
        )

    @app.exception_handler(InsufficientTrustBand)
    async def _band(request: Request, exc: InsufficientTrustBand) -> JSONResponse:
        return _respond(
            request,
            Problem(
                str(exc),
                slug="insufficient-trust-band",
                status=422,
                requiredBand=exc.required,
                currentBand=exc.current,
            ),
        )

    @app.exception_handler(InvalidReferralTransition)
    async def _transition(request: Request, exc: InvalidReferralTransition) -> JSONResponse:
        return _respond(request, Problem(str(exc), slug="conflict", status=409, title="Conflict"))

    @app.exception_handler(StaleAggregateError)
    async def _stale(request: Request, exc: StaleAggregateError) -> JSONResponse:
        return _respond(
            request,
            Problem(
                "The referral was modified concurrently; retry the request.",
                slug="conflict",
                status=409,
                title="Conflict",
            ),
        )

    @app.exception_handler(InvalidCursorError)
    async def _cursor(request: Request, exc: InvalidCursorError) -> JSONResponse:
        return _respond(request, Problem(str(exc), slug="invalid-cursor", status=400))
