from uuid import uuid4

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker, create_async_engine
from trustos_core.messaging import (
    ConsumedEvent,
    IdempotentConsumer,
    InMemoryProcessedEventStore,
    InMemoryProducer,
    Message,
    NoopProducer,
    SqlProcessedEventStore,
)
from trustos_core.outbox import make_processed_events_table


def _event(event_type: str = "referral.referral.submitted.v1") -> ConsumedEvent:
    return ConsumedEvent(event_id=uuid4(), event_type=event_type, payload=b"{}")


async def test_duplicate_event_processed_once() -> None:
    consumer = IdempotentConsumer(group_id="g1", store=InMemoryProcessedEventStore())
    calls: list[ConsumedEvent] = []

    @consumer.on("trustos.referral.referral", "referral.referral.submitted.v1")
    async def handle(event: ConsumedEvent, session: AsyncSession | None) -> None:
        calls.append(event)

    event = _event()
    await consumer.process(event)  # first delivery
    await consumer.process(event)  # redelivery (at-least-once)
    assert len(calls) == 1


async def test_unknown_event_type_skipped() -> None:
    consumer = IdempotentConsumer(group_id="g1", store=InMemoryProcessedEventStore())
    await consumer.process(_event("some.other.event.v1"))  # no handler -> no error


async def test_poison_message_goes_to_dlq_after_max_attempts() -> None:
    dlq = InMemoryProducer()
    consumer = IdempotentConsumer(
        group_id="g1", store=InMemoryProcessedEventStore(), dlq=dlq, max_attempts=3
    )
    attempts = 0

    @consumer.on("trustos.referral.referral", "referral.referral.submitted.v1")
    async def handle(event: ConsumedEvent, session: AsyncSession | None) -> None:
        nonlocal attempts
        attempts += 1
        raise RuntimeError("boom")

    await consumer.process(_event(), topic="trustos.referral.referral")
    assert attempts == 3
    assert len(dlq.sent) == 1
    assert dlq.sent[0].topic == "trustos.referral.referral.dlq"


async def test_different_groups_each_process() -> None:
    store = InMemoryProcessedEventStore()
    seen: list[str] = []

    def make(group: str) -> IdempotentConsumer:
        consumer = IdempotentConsumer(group_id=group, store=store)

        @consumer.on("t", "e.v1")
        async def handle(event: ConsumedEvent, session: AsyncSession | None) -> None:
            seen.append(group)

        return consumer

    event = _event("e.v1")
    await make("projections").process(event)
    await make("notifications").process(event)
    assert sorted(seen) == ["notifications", "projections"]


async def test_sql_store_dedups_in_handler_transaction() -> None:
    metadata = sa.MetaData()
    make_processed_events_table(metadata)
    engine = create_async_engine("sqlite+aiosqlite://")
    async with engine.begin() as conn:
        await conn.run_sync(metadata.create_all)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    consumer = IdempotentConsumer(
        group_id="g1", store=SqlProcessedEventStore(), session_factory=session_factory
    )
    calls = 0

    @consumer.on("t", "e.v1")
    async def handle(event: ConsumedEvent, session: AsyncSession | None) -> None:
        nonlocal calls
        calls += 1

    event = _event("e.v1")
    await consumer.process(event)
    await consumer.process(event)
    assert calls == 1
    await engine.dispose()


async def test_failed_handler_rolls_back_dedup_claim() -> None:
    """Crash mid-handler must not leave the event marked processed."""
    metadata = sa.MetaData()
    make_processed_events_table(metadata)
    engine = create_async_engine("sqlite+aiosqlite://")
    async with engine.begin() as conn:
        await conn.run_sync(metadata.create_all)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    consumer = IdempotentConsumer(
        group_id="g1",
        store=SqlProcessedEventStore(),
        session_factory=session_factory,
        max_attempts=2,
    )
    calls = 0

    @consumer.on("t", "e.v1")
    async def handle(event: ConsumedEvent, session: AsyncSession | None) -> None:
        nonlocal calls
        calls += 1
        if calls == 1:
            raise RuntimeError("transient")

    await consumer.process(_event("e.v1"))
    assert calls == 2  # retried, second attempt claimed and succeeded
    await engine.dispose()


async def test_noop_and_inmemory_producers() -> None:
    message = Message(topic="t", key="k", value=b"v", headers={"h": "1"})
    await NoopProducer().send(message)
    mem = InMemoryProducer()
    await mem.send(message)
    assert mem.sent == [message]
