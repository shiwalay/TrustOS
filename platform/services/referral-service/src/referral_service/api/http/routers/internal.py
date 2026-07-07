"""Liveness/readiness endpoints — pod probes, never exposed via the gateway."""

from __future__ import annotations

from fastapi import APIRouter

router = APIRouter(prefix="/internal", tags=["internal"], include_in_schema=False)


@router.get("/healthz")
async def healthz() -> dict[str, str]:
    return {"status": "ok"}


@router.get("/readyz")
async def readyz() -> dict[str, str]:
    return {"status": "ready"}
