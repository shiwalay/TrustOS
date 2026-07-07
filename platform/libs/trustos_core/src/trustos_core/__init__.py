"""TrustOS shared cross-cutting library (03-backend-architecture.md §4).

Modules:
- ids          UUIDv7 + prefixed public IDs (``ref_``, ``usr_``, ...)
- money        integer minor units + ISO 4217 (shared-context §1)
- domain       Entity / AggregateRoot / ValueObject / DomainEvent building blocks
- clock        Clock protocol + SystemClock / FakeClock
- problems     RFC 9457 Problem Details exceptions + FastAPI handlers
- idempotency  Idempotency-Key middleware (Redis-backed, in-memory for tests)
- pagination   opaque HMAC-signed base64 cursors
- outbox       transactional outbox table + writer (05-data-architecture.md §2.3)
- messaging    Kafka producer/consumer wrappers + idempotent-consumer pattern
- settings     pydantic-settings base for services
- otel         one-call OpenTelemetry setup
"""
