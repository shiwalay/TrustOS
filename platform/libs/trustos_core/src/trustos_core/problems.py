"""RFC 9457 Problem Details: exception types + FastAPI handlers (shared-context §5,
04-api-design.md §2.1). Every non-2xx body is ``application/problem+json``."""

from __future__ import annotations

from typing import Any

from fastapi import FastAPI, Request
from fastapi.exceptions import RequestValidationError
from starlette.exceptions import HTTPException as StarletteHTTPException
from starlette.responses import JSONResponse

PROBLEM_TYPE_BASE = "https://api.trustos.com/problems/"
PROBLEM_MEDIA_TYPE = "application/problem+json"


class Problem(Exception):
    """Raise anywhere below the API layer boundary to produce an RFC 9457 response.

    ``extras`` become top-level extension members (e.g. ``existingReferralId``).
    """

    slug = "internal-error"
    status = 500
    title = "Internal error"

    def __init__(
        self,
        detail: str,
        *,
        slug: str | None = None,
        status: int | None = None,
        title: str | None = None,
        **extras: Any,
    ) -> None:
        super().__init__(detail)
        self.detail = detail
        if slug is not None:
            self.slug = slug
        if status is not None:
            self.status = status
        if title is not None:
            self.title = title
        elif slug is not None:
            self.title = slug.replace("-", " ").capitalize()
        self.extras = extras

    def to_document(self, instance: str | None = None) -> dict[str, Any]:
        doc: dict[str, Any] = {
            "type": f"{PROBLEM_TYPE_BASE}{self.slug}",
            "title": self.title,
            "status": self.status,
            "detail": self.detail,
        }
        if instance is not None:
            doc["instance"] = instance
        doc.update(self.extras)
        return doc


class NotFoundProblem(Problem):
    """404 — absent OR unauthorized-to-know (no existence oracle)."""

    slug = "not-found"
    status = 404
    title = "Not found"


class ConflictProblem(Problem):
    slug = "conflict"
    status = 409
    title = "Conflict"


class ValidationProblem(Problem):
    slug = "validation-failed"
    status = 400
    title = "Validation failed"


class UnprocessableProblem(Problem):
    slug = "unprocessable"
    status = 422
    title = "Unprocessable"


class UnauthenticatedProblem(Problem):
    slug = "unauthenticated"
    status = 401
    title = "Unauthenticated"


def problem_response(problem: Problem, *, instance: str | None = None) -> JSONResponse:
    return JSONResponse(
        problem.to_document(instance=instance),
        status_code=problem.status,
        media_type=PROBLEM_MEDIA_TYPE,
    )


def install_problem_details(app: FastAPI) -> None:
    """Register RFC 9457 handlers: Problem, request validation, bare HTTPException."""

    @app.exception_handler(Problem)
    async def _handle_problem(request: Request, exc: Problem) -> JSONResponse:
        return problem_response(exc, instance=request.url.path)

    @app.exception_handler(RequestValidationError)
    async def _handle_validation(request: Request, exc: RequestValidationError) -> JSONResponse:
        errors = [
            {
                "pointer": "/" + "/".join(str(loc) for loc in err.get("loc", ())),
                "message": err.get("msg", "invalid"),
            }
            for err in exc.errors()
        ]
        problem = ValidationProblem("Request failed schema validation.", errors=errors)
        return problem_response(problem, instance=request.url.path)

    @app.exception_handler(StarletteHTTPException)
    async def _handle_http(request: Request, exc: StarletteHTTPException) -> JSONResponse:
        slug = {404: "not-found", 405: "method-not-allowed", 401: "unauthenticated"}.get(
            exc.status_code, "http-error"
        )
        problem = Problem(str(exc.detail), slug=slug, status=exc.status_code)
        return problem_response(problem, instance=request.url.path)
