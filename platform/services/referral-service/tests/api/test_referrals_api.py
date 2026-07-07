"""API test with httpx ASGI transport + in-memory infra (03 §6): proves
submit -> qualify -> convert end-to-end, idempotent replay of the same
Idempotency-Key, Problem Details errors, and cursor pagination."""

from __future__ import annotations

from collections.abc import AsyncIterator
from datetime import timedelta

import httpx
import pytest
from fakes import InMemoryStore, build_test_container
from helpers import make_campaign
from referral_service.domain.events import ReferralConverted, ReferralQualified, ReferralSubmitted
from referral_service.main import create_app
from trustos_core.clock import FakeClock
from trustos_core.ids import prefixed_uuid7

REFERRER = {"x-actor-id": "usr_referrer", "x-actor-type": "user"}
ORG_ADMIN = {"x-actor-id": "org_admin", "x-actor-type": "org"}


@pytest.fixture
def store() -> InMemoryStore:
    return InMemoryStore()


@pytest.fixture
def campaign_id(store: InMemoryStore) -> str:
    campaign = make_campaign()  # published, 5% rate scheme, starter band
    store.campaigns[campaign.id] = campaign
    return campaign.id


@pytest.fixture
def clock() -> FakeClock:
    return FakeClock()


@pytest.fixture
async def client(store: InMemoryStore, clock: FakeClock) -> AsyncIterator[httpx.AsyncClient]:
    app = create_app(build_test_container(store, clock=clock))
    transport = httpx.ASGITransport(app=app)
    async with httpx.AsyncClient(transport=transport, base_url="http://test") as client:
        yield client


def submit_body(campaign_id: str, prospect: str | None = None) -> dict[str, str]:
    return {"campaignId": campaign_id, "prospectContactId": prospect or prefixed_uuid7("cnt")}


async def test_submit_qualify_convert_flow(
    client: httpx.AsyncClient, store: InMemoryStore, campaign_id: str
) -> None:
    # 1. submit
    created = await client.post(
        "/v1/referrals",
        json=submit_body(campaign_id),
        headers={**REFERRER, "Idempotency-Key": "sub-1"},
    )
    assert created.status_code == 201, created.text
    body = created.json()
    referral_id = body["id"]
    assert referral_id.startswith("ref_")
    assert body["status"] == "submitted"
    assert body["campaignId"] == campaign_id
    assert body["schemeSnapshot"]["rateBasisPoints"] == 500
    assert body["links"]["self"] == f"/v1/referrals/{referral_id}"

    # 2. qualify (org verdict)
    qualified = await client.post(f"/v1/referrals/{referral_id}/qualify", headers=ORG_ADMIN)
    assert qualified.status_code == 200
    assert qualified.json() == {"id": referral_id, "status": "qualified"}

    # 3. convert (deal won; 5% of 2,50,000)
    converted = await client.post(
        f"/v1/referrals/{referral_id}/convert",
        json={"dealId": prefixed_uuid7("dl"), "dealValue": {"amountMinor": 250_000, "currency": "INR"}},
        headers={"x-actor-id": "system", "x-actor-type": "system"},
    )
    assert converted.status_code == 200
    assert converted.json()["status"] == "converted"
    assert converted.json()["commission"] == {"amountMinor": 12_500, "currency": "INR"}

    # 4. detail reflects the terminal-so-far state (camelCase JSON)
    detail = await client.get(f"/v1/referrals/{referral_id}")
    assert detail.status_code == 200
    assert detail.json()["status"] == "converted"
    assert detail.json()["commission"]["amountMinor"] == 12_500

    # every state change hit the (captured) outbox
    assert [type(e) for e in store.outbox] == [ReferralSubmitted, ReferralQualified, ReferralConverted]


async def test_idempotency_key_replays_submit(
    client: httpx.AsyncClient, store: InMemoryStore, campaign_id: str
) -> None:
    body = submit_body(campaign_id)
    headers = {**REFERRER, "Idempotency-Key": "replay-me"}

    first = await client.post("/v1/referrals", json=body, headers=headers)
    replay = await client.post("/v1/referrals", json=body, headers=headers)

    assert first.status_code == replay.status_code == 201
    assert replay.json() == first.json()  # same referral id — handler ran once
    assert replay.headers.get("Idempotency-Replayed") == "true"
    assert len(store.referrals) == 1
    assert len(store.outbox) == 1  # no duplicate ReferralSubmitted

    # same key + different body is a client bug -> 422 problem
    other = await client.post(
        "/v1/referrals", json=submit_body(campaign_id), headers=headers
    )
    assert other.status_code == 422
    assert other.json()["type"].endswith("/idempotency-key-reuse")


async def test_duplicate_referral_problem(client: httpx.AsyncClient, campaign_id: str) -> None:
    prospect = prefixed_uuid7("cnt")
    first = await client.post("/v1/referrals", json=submit_body(campaign_id, prospect), headers=REFERRER)
    dup = await client.post("/v1/referrals", json=submit_body(campaign_id, prospect), headers=REFERRER)
    assert dup.status_code == 409
    problem = dup.json()
    assert dup.headers["content-type"].startswith("application/problem+json")
    assert problem["type"] == "https://api.trustos.com/problems/duplicate-referral"
    assert problem["existingReferralId"] == first.json()["id"]
    assert problem["instance"] == "/v1/referrals"


async def test_unknown_campaign_is_404_problem(client: httpx.AsyncClient) -> None:
    resp = await client.post("/v1/referrals", json=submit_body("cmp_missing"), headers=REFERRER)
    assert resp.status_code == 404
    assert resp.json()["type"].endswith("/not-found")


async def test_write_without_actor_context_is_401(client: httpx.AsyncClient, campaign_id: str) -> None:
    resp = await client.post("/v1/referrals", json=submit_body(campaign_id))
    assert resp.status_code == 401
    assert resp.json()["type"].endswith("/unauthenticated")


async def test_illegal_transition_is_409(client: httpx.AsyncClient, campaign_id: str) -> None:
    referral_id = (
        await client.post("/v1/referrals", json=submit_body(campaign_id), headers=REFERRER)
    ).json()["id"]
    # convert straight from submitted -> conflict
    resp = await client.post(
        f"/v1/referrals/{referral_id}/convert",
        json={"dealId": "dl_1", "dealValue": {"amountMinor": 100, "currency": "INR"}},
        headers=ORG_ADMIN,
    )
    assert resp.status_code == 409
    assert resp.json()["type"].endswith("/conflict")


async def test_list_with_status_filter_and_cursor_pagination(
    client: httpx.AsyncClient, clock: FakeClock, campaign_id: str
) -> None:
    ids = []
    for _ in range(5):
        resp = await client.post("/v1/referrals", json=submit_body(campaign_id), headers=REFERRER)
        ids.append(resp.json()["id"])
        clock.advance(timedelta(minutes=1))
    # qualify two of them
    for referral_id in ids[:2]:
        await client.post(f"/v1/referrals/{referral_id}/qualify", headers=ORG_ADMIN)

    # filter[status]
    qualified = (await client.get("/v1/referrals", params={"filter[status]": "qualified"})).json()
    assert {r["id"] for r in qualified["data"]} == set(ids[:2])
    assert qualified["pageInfo"]["hasMore"] is False

    # cursor pagination: newest first, limit 2 -> 2 + 2 + 1
    seen: list[str] = []
    cursor: str | None = None
    for expected in (2, 2, 1):
        params: dict[str, str] = {"limit": "2"}
        if cursor:
            params["cursor"] = cursor
        page = (await client.get("/v1/referrals", params=params)).json()
        assert len(page["data"]) == expected
        seen += [r["id"] for r in page["data"]]
        cursor = page["pageInfo"]["nextCursor"]
        assert page["pageInfo"]["hasMore"] is (expected == 2)
    assert cursor is None
    assert seen == list(reversed(ids))  # submitted_at DESC
    assert len(set(seen)) == 5  # no overlaps across pages

    # tampered cursor -> 400 invalid-cursor problem
    bad = await client.get("/v1/referrals", params={"limit": "2", "cursor": "AAAA" + "b" * 20})
    assert bad.status_code == 400
    assert bad.json()["type"].endswith("/invalid-cursor")


async def test_list_limit_over_100_fails_validation(client: httpx.AsyncClient) -> None:
    resp = await client.get("/v1/referrals", params={"limit": "101"})
    assert resp.status_code == 400
    assert resp.json()["type"].endswith("/validation-failed")
