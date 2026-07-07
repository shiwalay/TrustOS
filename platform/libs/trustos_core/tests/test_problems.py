import httpx
import pytest
from fastapi import FastAPI
from pydantic import BaseModel
from trustos_core.problems import (
    ConflictProblem,
    NotFoundProblem,
    Problem,
    install_problem_details,
)


class _Body(BaseModel):
    name: str


@pytest.fixture
def app() -> FastAPI:
    app = FastAPI()
    install_problem_details(app)

    @app.get("/missing")
    async def missing() -> None:
        raise NotFoundProblem("Referral ref_x does not exist.")

    @app.get("/dup")
    async def dup() -> None:
        raise ConflictProblem(
            "An open referral already exists.",
            slug="duplicate-referral",
            existingReferralId="ref_01",
        )

    @app.post("/things")
    async def things(body: _Body) -> dict[str, str]:
        return {"ok": body.name}

    return app


async def _get(app: FastAPI, path: str) -> httpx.Response:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        return await client.get(path)


async def test_problem_renders_rfc9457(app: FastAPI) -> None:
    resp = await _get(app, "/missing")
    assert resp.status_code == 404
    assert resp.headers["content-type"].startswith("application/problem+json")
    body = resp.json()
    assert body["type"] == "https://api.trustos.com/problems/not-found"
    assert body["status"] == 404
    assert body["instance"] == "/missing"


async def test_extension_members_and_custom_slug(app: FastAPI) -> None:
    resp = await _get(app, "/dup")
    body = resp.json()
    assert resp.status_code == 409
    assert body["type"].endswith("/duplicate-referral")
    assert body["existingReferralId"] == "ref_01"


async def test_request_validation_becomes_problem(app: FastAPI) -> None:
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        resp = await client.post("/things", json={})
    assert resp.status_code == 400
    body = resp.json()
    assert body["type"].endswith("/validation-failed")
    assert body["errors"][0]["pointer"] == "/body/name"


async def test_unknown_route_is_problem_json(app: FastAPI) -> None:
    resp = await _get(app, "/nope")
    assert resp.status_code == 404
    assert resp.headers["content-type"].startswith("application/problem+json")
    assert resp.json()["type"].endswith("/not-found")


def test_problem_document_shape() -> None:
    p = Problem("boom", slug="upstream-degraded", status=503)
    doc = p.to_document(instance="/v1/x")
    assert doc == {
        "type": "https://api.trustos.com/problems/upstream-degraded",
        "title": "Upstream degraded",
        "status": 503,
        "detail": "boom",
        "instance": "/v1/x",
    }
