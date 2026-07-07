"""Idempotency-Key middleware (shared-context §5; 03-backend-architecture.md §4.1).

Semantics: first request **reserves** the key and stores a fingerprint of the
request body; concurrent duplicates get 409 + Retry-After; completed duplicates
**replay the stored response** with ``Idempotency-Replayed: true``; same key +
different body is a client bug -> 422 ``idempotency-key-reuse``.

Backends: Redis in production (24 h TTL), in-memory for tests / local dev.
"""

from __future__ import annotations

import hashlib
import json
import time
from typing import Protocol

from starlette.middleware.base import BaseHTTPMiddleware, RequestResponseEndpoint
from starlette.requests import Request
from starlette.responses import JSONResponse, Response
from starlette.types import ASGIApp

from trustos_core.problems import PROBLEM_MEDIA_TYPE, PROBLEM_TYPE_BASE

DEFAULT_TTL_SECONDS = 24 * 3600
_MUTATING = frozenset({"POST", "PATCH", "PUT", "DELETE"})


class IdempotencyBackend(Protocol):
    """Minimal KV surface the middleware needs. All values are JSON strings."""

    async def put_if_absent(self, key: str, value: str, ttl_seconds: int) -> bool: ...
    async def get(self, key: str) -> str | None: ...
    async def put(self, key: str, value: str, ttl_seconds: int) -> None: ...
    async def delete(self, key: str) -> None: ...


class InMemoryIdempotencyBackend:
    """Test / local-dev backend. TTL honored via monotonic expiry."""

    def __init__(self) -> None:
        self._data: dict[str, tuple[str, float]] = {}

    def _live(self, key: str) -> str | None:
        entry = self._data.get(key)
        if entry is None:
            return None
        value, expires_at = entry
        if time.monotonic() >= expires_at:
            del self._data[key]
            return None
        return value

    async def put_if_absent(self, key: str, value: str, ttl_seconds: int) -> bool:
        if self._live(key) is not None:
            return False
        self._data[key] = (value, time.monotonic() + ttl_seconds)
        return True

    async def get(self, key: str) -> str | None:
        return self._live(key)

    async def put(self, key: str, value: str, ttl_seconds: int) -> None:
        self._data[key] = (value, time.monotonic() + ttl_seconds)

    async def delete(self, key: str) -> None:
        self._data.pop(key, None)


class RedisIdempotencyBackend:
    """Production backend over redis.asyncio (lazy import; ``trustos-core[redis]``)."""

    def __init__(self, redis_url: str) -> None:
        import redis.asyncio as aioredis

        self._redis = aioredis.from_url(redis_url, decode_responses=True)

    async def put_if_absent(self, key: str, value: str, ttl_seconds: int) -> bool:
        return bool(await self._redis.set(key, value, nx=True, ex=ttl_seconds))

    async def get(self, key: str) -> str | None:
        value = await self._redis.get(key)
        return value if value is None else str(value)

    async def put(self, key: str, value: str, ttl_seconds: int) -> None:
        await self._redis.set(key, value, ex=ttl_seconds)

    async def delete(self, key: str) -> None:
        await self._redis.delete(key)


class IdempotencyMiddleware(BaseHTTPMiddleware):
    def __init__(
        self,
        app: ASGIApp,
        backend: IdempotencyBackend,
        ttl_seconds: int = DEFAULT_TTL_SECONDS,
    ) -> None:
        super().__init__(app)
        self._backend = backend
        self._ttl = ttl_seconds

    async def dispatch(self, request: Request, call_next: RequestResponseEndpoint) -> Response:
        key = request.headers.get("Idempotency-Key")
        if request.method not in _MUTATING or key is None:
            return await call_next(request)

        actor = request.headers.get("x-actor-id", "anon")  # set by gateway from JWT
        body = await request.body()
        fingerprint = hashlib.sha256(body + request.url.path.encode()).hexdigest()
        rkey = f"idem:{actor}:{key}"

        # atomically reserve: {state: in_flight, fp: ...}
        reserved = await self._backend.put_if_absent(
            rkey, json.dumps({"state": "in_flight", "fp": fingerprint}), self._ttl
        )
        if not reserved:
            stored = json.loads(await self._backend.get(rkey) or "{}")
            if stored.get("fp") != fingerprint:
                return _problem(
                    422,
                    "idempotency-key-reuse",
                    "Idempotency-Key was already used with a different request body",
                )
            if stored.get("state") == "in_flight":
                return _problem(
                    409, "request-in-flight", "An identical request is being processed", retry_after=1
                )
            return Response(
                content=stored["body"],
                status_code=stored["status"],
                headers={**stored["headers"], "Idempotency-Replayed": "true"},
            )

        response = await call_next(request)
        if response.status_code < 500:  # never replay transient failures
            body_bytes = b"".join([chunk async for chunk in response.body_iterator])  # type: ignore[attr-defined]
            await self._backend.put(
                rkey,
                json.dumps(
                    {
                        "state": "done",
                        "fp": fingerprint,
                        "status": response.status_code,
                        "headers": {
                            "content-type": response.headers.get("content-type", "application/json")
                        },
                        "body": body_bytes.decode(),
                    }
                ),
                self._ttl,
            )
            return Response(
                content=body_bytes,
                status_code=response.status_code,
                headers=dict(response.headers),
            )
        await self._backend.delete(rkey)  # allow retry after 5xx
        return response


def _problem(status: int, slug: str, detail: str, retry_after: int | None = None) -> JSONResponse:
    headers = {"Retry-After": str(retry_after)} if retry_after else {}
    return JSONResponse(
        {
            "type": f"{PROBLEM_TYPE_BASE}{slug}",
            "title": slug.replace("-", " "),
            "status": status,
            "detail": detail,
        },
        status_code=status,
        media_type=PROBLEM_MEDIA_TYPE,
        headers=headers,
    )
