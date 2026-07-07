"""Kafka wrappers + the idempotent-consumer pattern (03-backend-architecture.md §4.2).

At-least-once delivery (shared-context §3) means every consumer must dedup by
``event_id``. ``IdempotentConsumer`` makes the dedup record and the handler's DB
writes share one transaction — the only way "processed exactly once" is true.

Kafka clients are thin wrappers over aiokafka (lazy import; ``trustos-core[kafka]``)
and degrade to ``InMemoryProducer`` / direct ``IdempotentConsumer.process()`` calls
in tests — no broker required.
"""

from __future__ import annotations

import contextlib
import logging
from collections.abc import AsyncIterator, Awaitable, Callable, Mapping
from dataclasses import dataclass, field
from typing import Any, Protocol
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker

log = logging.getLogger(__name__)


# ── messages ────────────────────────────────────────────────────────────────


@dataclass(frozen=True, slots=True)
class Message:
    topic: str
    key: str
    value: bytes
    headers: Mapping[str, str] = field(default_factory=dict)


@dataclass(frozen=True, slots=True)
class ConsumedEvent:
    """CloudEvents-shaped envelope as seen by handlers (payload codec-agnostic)."""

    event_id: UUID
    event_type: str
    payload: bytes
    headers: Mapping[str, str] = field(default_factory=dict)


# ── producers ───────────────────────────────────────────────────────────────


class Producer(Protocol):
    async def send(self, message: Message) -> None: ...


class NoopProducer:
    """Degraded mode: events are dropped (outbox+Debezium is the real publish path)."""

    async def send(self, message: Message) -> None:
        return None


class InMemoryProducer:
    """Test double: records every message sent."""

    def __init__(self) -> None:
        self.sent: list[Message] = []

    async def send(self, message: Message) -> None:
        self.sent.append(message)


class KafkaProducer:
    """Thin aiokafka wrapper. Lazy import so the broker/client is optional."""

    def __init__(self, bootstrap_servers: str) -> None:
        from aiokafka import AIOKafkaProducer

        self._producer = AIOKafkaProducer(bootstrap_servers=bootstrap_servers, acks="all")
        self._started = False

    async def start(self) -> None:
        await self._producer.start()
        self._started = True

    async def stop(self) -> None:
        if self._started:
            await self._producer.stop()
            self._started = False

    async def send(self, message: Message) -> None:
        await self._producer.send_and_wait(
            message.topic,
            key=message.key.encode(),
            value=message.value,
            headers=[(k, v.encode()) for k, v in message.headers.items()],
        )


# ── idempotent consumer ─────────────────────────────────────────────────────


class ProcessedEventStore(Protocol):
    """Claims an event id for a consumer group. True = first delivery, process it.
    ``release`` undoes a claim after a failed attempt (transactional stores no-op:
    the rollback already discarded the claim row)."""

    async def claim(self, session: AsyncSession | None, event_id: UUID, consumer_group: str) -> bool: ...
    async def release(self, event_id: UUID, consumer_group: str) -> None: ...


class SqlProcessedEventStore:
    """Dedup inside the handler's transaction: INSERT ... ON CONFLICT DO NOTHING."""

    async def claim(self, session: AsyncSession | None, event_id: UUID, consumer_group: str) -> bool:
        if session is None:
            raise ValueError("SqlProcessedEventStore requires a database session")
        result = await session.execute(
            sa.text(
                "INSERT INTO processed_events (event_id, consumer_group) "
                "VALUES (:eid, :grp) ON CONFLICT DO NOTHING"
            ),
            {"eid": str(event_id), "grp": consumer_group},
        )
        rowcount: int = getattr(result, "rowcount", 0)  # CursorResult for DML statements
        return rowcount == 1

    async def release(self, event_id: UUID, consumer_group: str) -> None:
        return None  # the failed transaction's rollback already discarded the claim


class InMemoryProcessedEventStore:
    """Test double: dedup via an in-process set."""

    def __init__(self) -> None:
        self._seen: set[tuple[UUID, str]] = set()

    async def claim(self, session: AsyncSession | None, event_id: UUID, consumer_group: str) -> bool:
        claim_key = (event_id, consumer_group)
        if claim_key in self._seen:
            return False
        self._seen.add(claim_key)
        return True

    async def release(self, event_id: UUID, consumer_group: str) -> None:
        self._seen.discard((event_id, consumer_group))


Handler = Callable[[ConsumedEvent, AsyncSession | None], Awaitable[None]]


class IdempotentConsumer:
    """Register handlers by event type; ``process()`` guarantees:

    - per-event dedup via ``processed_events(event_id, consumer_group)`` inside the
      handler's transaction (dedup + writes commit or roll back together)
    - poison messages -> DLQ (``<topic>.dlq``) after ``max_attempts``
    - unknown event types are skipped (topics carry multiple types)

    With ``session_factory=None`` + ``InMemoryProcessedEventStore`` this runs fully
    in-memory — the test seam. ``KafkaConsumerApp`` is the broker-backed runtime.
    """

    def __init__(
        self,
        *,
        group_id: str,
        store: ProcessedEventStore,
        session_factory: async_sessionmaker[AsyncSession] | None = None,
        dlq: Producer | None = None,
        max_attempts: int = 5,
    ) -> None:
        self._group_id = group_id
        self._store = store
        self._session_factory = session_factory
        self._dlq = dlq or NoopProducer()
        self._max_attempts = max_attempts
        self._handlers: dict[str, Handler] = {}
        self.topics: set[str] = set()

    def on(self, topic: str, event_type: str) -> Callable[[Handler], Handler]:
        def register(fn: Handler) -> Handler:
            self._handlers[event_type] = fn
            self.topics.add(topic)
            return fn

        return register

    @contextlib.asynccontextmanager
    async def _transaction(self) -> AsyncIterator[AsyncSession | None]:
        if self._session_factory is None:
            yield None
        else:
            async with self._session_factory() as session, session.begin():
                yield session

    async def process(self, event: ConsumedEvent, *, topic: str = "") -> None:
        handler = self._handlers.get(event.event_type)
        if handler is None:
            return  # not ours; topic carries multiple types
        for attempt in range(1, self._max_attempts + 1):
            try:
                async with self._transaction() as session:
                    claimed = await self._store.claim(session, event.event_id, self._group_id)
                    if not claimed:
                        log.info("duplicate event skipped", extra={"event_id": str(event.event_id)})
                        return
                    await handler(event, session)  # handler writes share this tx
                return
            except Exception:
                log.exception(
                    "handler failed", extra={"event_id": str(event.event_id), "attempt": attempt}
                )
                await self._store.release(event.event_id, self._group_id)
                if attempt == self._max_attempts:
                    await self._dlq.send(
                        Message(
                            topic=f"{topic or event.event_type}.dlq",
                            key=str(event.event_id),
                            value=event.payload,
                            headers=dict(event.headers),
                        )
                    )
                    return


class KafkaConsumerApp:
    """Broker-backed runtime for ``IdempotentConsumer`` (aiokafka; lazy import).

    Offsets are committed AFTER the DB transaction commits: crash between them =
    redelivery, which dedup absorbs. At-least-once + idempotent handler =
    effectively-once.
    """

    def __init__(self, consumer: IdempotentConsumer, *, bootstrap_servers: str, group_id: str) -> None:
        from aiokafka import AIOKafkaConsumer

        self._logic = consumer
        self._consumer = AIOKafkaConsumer(
            bootstrap_servers=bootstrap_servers,
            group_id=group_id,
            enable_auto_commit=False,
            isolation_level="read_committed",
        )

    async def run(self) -> None:
        self._consumer.subscribe(list(self._logic.topics))
        await self._consumer.start()
        try:
            async for record in self._consumer:
                event = _decode_record(record)
                if event is not None:
                    await self._logic.process(event, topic=record.topic)
                await self._consumer.commit()
        finally:
            await self._consumer.stop()


def _decode_record(record: Any) -> ConsumedEvent | None:
    headers = {k: v.decode() for k, v in (record.headers or [])}
    event_id = headers.get("event_id") or headers.get("ce_id")
    event_type = headers.get("event_type") or headers.get("ce_type")
    if event_id is None or event_type is None:
        log.warning("record missing event envelope headers; skipping", extra={"topic": record.topic})
        return None
    return ConsumedEvent(
        event_id=UUID(event_id), event_type=event_type, payload=record.value or b"", headers=headers
    )
