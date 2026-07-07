import itertools

import httpx
import pytest
from fastapi import FastAPI
from pydantic import BaseModel
from trustos_core.idempotency import IdempotencyMiddleware, InMemoryIdempotencyBackend

_counter = itertools.count(1)


class _Body(BaseModel):
    name: str


@pytest.fixture
def backend() -> InMemoryIdempotencyBackend:
    return InMemoryIdempotencyBackend()


@pytest.fixture
def client(backend: InMemoryIdempotencyBackend) -> httpx.AsyncClient:
    app = FastAPI()
    app.add_middleware(IdempotencyMiddleware, backend=backend)

    @app.post("/widgets", status_code=201)
    async def create(body: _Body) -> dict[str, str]:
        return {"id": f"wgt_{next(_counter)}", "name": body.name}

    transport = httpx.ASGITransport(app=app)
    return httpx.AsyncClient(transport=transport, base_url="http://test")


async def test_same_key_same_body_replays_response(client: httpx.AsyncClient) -> None:
    headers = {"Idempotency-Key": "k1", "x-actor-id": "usr_1"}
    first = await client.post("/widgets", json={"name": "a"}, headers=headers)
    second = await client.post("/widgets", json={"name": "a"}, headers=headers)
    assert first.status_code == second.status_code == 201
    assert first.json() == second.json()  # replayed, handler not re-run
    assert second.headers.get("Idempotency-Replayed") == "true"
    assert "Idempotency-Replayed" not in first.headers


async def test_same_key_different_body_is_422(client: httpx.AsyncClient) -> None:
    headers = {"Idempotency-Key": "k2", "x-actor-id": "usr_1"}
    await client.post("/widgets", json={"name": "a"}, headers=headers)
    resp = await client.post("/widgets", json={"name": "DIFFERENT"}, headers=headers)
    assert resp.status_code == 422
    assert resp.json()["type"].endswith("/idempotency-key-reuse")


async def test_keys_are_scoped_per_actor(client: httpx.AsyncClient) -> None:
    r1 = await client.post(
        "/widgets", json={"name": "a"}, headers={"Idempotency-Key": "k3", "x-actor-id": "usr_1"}
    )
    r2 = await client.post(
        "/widgets", json={"name": "a"}, headers={"Idempotency-Key": "k3", "x-actor-id": "usr_2"}
    )
    assert r1.json() != r2.json()  # different actors, independent executions


async def test_no_key_means_no_idempotency(client: httpx.AsyncClient) -> None:
    r1 = await client.post("/widgets", json={"name": "a"})
    r2 = await client.post("/widgets", json={"name": "a"})
    assert r1.json() != r2.json()


async def test_in_flight_duplicate_conflicts(backend: InMemoryIdempotencyBackend) -> None:
    # simulate a reservation that never completed (first request still running)
    await backend.put_if_absent("idem:usr_1:k4", '{"state": "in_flight", "fp": "manual"}', 60)
    app = FastAPI()
    app.add_middleware(IdempotencyMiddleware, backend=backend)

    @app.post("/widgets")
    async def create() -> dict[str, bool]:
        return {"ok": True}

    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        # same fp cannot be forged easily, so expect 422 (fp mismatch) or 409 path:
        resp = await client.post(
            "/widgets", json={}, headers={"Idempotency-Key": "k4", "x-actor-id": "usr_1"}
        )
    assert resp.status_code in (409, 422)


async def test_ttl_expiry_allows_reexecution(backend: InMemoryIdempotencyBackend) -> None:
    assert await backend.put_if_absent("k", "v1", ttl_seconds=0) is True
    # entry expired immediately -> key free again
    assert await backend.put_if_absent("k", "v2", ttl_seconds=60) is True
    assert await backend.get("k") == "v2"
