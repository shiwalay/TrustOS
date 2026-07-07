# TrustOS `platform` — backend monorepo

One `uv` workspace (Python 3.12), per-service deployables, shared cross-cutting
libraries. Conforms to `../docs/_shared-context.md` and
`../docs/03-backend-architecture.md`; the fully-implemented exemplar service is
**`services/referral-service`**.

```
platform/
├── libs/
│   └── trustos_core/        # ids (uuid7 + prefixes), Money, domain blocks, Problem Details,
│                            # idempotency middleware, cursor pagination, outbox, Kafka wrappers,
│                            # settings base, OTel setup — each with unit tests
├── services/
│   └── referral-service/    # api/ → application/ → domain/ ← infrastructure/ (Clean Architecture)
├── docker-compose.dev.yml   # postgres:16, redis:7, kafka (KRaft), neo4j:5, qdrant, temporal (+ui)
├── Makefile                 # install / lint / typecheck / test / up / down
└── pyproject.toml           # uv workspace root: ruff, mypy strict, pytest config
```

## Prerequisites

- [uv](https://docs.astral.sh/uv/) (`curl -LsSf https://astral.sh/uv/install.sh | sh`)
- Docker (only for `make up` and running against real infrastructure)

uv provisions Python 3.12 automatically if it is not on the machine.

## Quick start

```bash
make install       # uv sync — resolves the whole workspace into .venv
make test          # uv run pytest (unit + API tests; no Docker needed)
make lint          # uv run ruff check .
make typecheck     # uv run mypy
```

## Running referral-service locally

```bash
make up            # postgres, redis, kafka, neo4j, qdrant, temporal (+ UI on :8233)
cp .env.example services/referral-service/.env

# apply the schema (docs/05 §3.5 DDL)
cd services/referral-service
uv run alembic upgrade head

# serve
uv run uvicorn --factory referral_service.main:create_app --reload --port 8000
```

Then e.g.:

```bash
curl -s -X POST localhost:8000/v1/referrals \
  -H 'content-type: application/json' \
  -H 'x-actor-id: usr_01hv9k3d7qab0000000000' \
  -H 'Idempotency-Key: 6c9d0d3a-2b1e-4a7f-9c3d-1f2e3a4b5c6d' \
  -d '{"campaignId": "cmp_...", "prospectContactId": "cnt_..."}'
```

Endpoints (04-api-design.md §3.7): `POST /v1/referrals`,
`POST /v1/referrals/{id}/qualify`, `POST /v1/referrals/{id}/convert`,
`GET /v1/referrals/{id}`, `GET /v1/referrals?filter[status]=&cursor=&limit=`.

All mutating routes honor `Idempotency-Key`; errors are RFC 9457
`application/problem+json`; list endpoints use opaque HMAC-signed cursors.

## Tests

- `libs/trustos_core/tests` — focused unit tests per module (ids, money, domain,
  problems, idempotency, pagination, outbox, messaging, settings/otel).
- `services/referral-service/tests/unit` — domain state machine + command handlers
  against in-memory fakes (zero I/O).
- `services/referral-service/tests/api` — httpx ASGI test proving
  submit → qualify → convert, idempotent replay, problem details, cursor pagination.

## Type checking scope

`mypy --strict` is enforced on `trustos_core` and referral-service's
`domain/` + `application/` layers (the layers that must stay framework-free and
correct). `infrastructure/` and `api/` are excluded for now — SQLAlchemy Core /
FastAPI decorator typing fights strict mode; they are covered by ruff + tests.
Widen `[tool.mypy] files` in `pyproject.toml` as those stubs improve.

## CI

`.github/workflows/ci.yml` (repo root): lint → typecheck → test on the
`platform` workspace via `astral-sh/setup-uv`.
