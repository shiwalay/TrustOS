import json
from dataclasses import dataclass
from datetime import UTC, datetime

import pytest
import sqlalchemy as sa
from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from trustos_core.domain import DomainEvent
from trustos_core.ids import prefixed_uuid7, uuid_from_public_id
from trustos_core.outbox import (
    EventMeta,
    OutboxWriter,
    UnregisteredEventError,
    make_outbox_table,
    make_processed_events_table,
)


@dataclass(frozen=True, slots=True, kw_only=True)
class ReferralSubmitted(DomainEvent):
    referral_id: str
    campaign_id: str


NOW = datetime(2026, 7, 7, 12, 0, tzinfo=UTC)

REGISTRY = {
    ReferralSubmitted: EventMeta(
        event_type="referral.referral.submitted.v1",
        aggregate_type="referral",
        aggregate_id=lambda e: e.referral_id,  # type: ignore[attr-defined]
    )
}


def _writer(table: sa.Table) -> OutboxWriter:
    return OutboxWriter(table=table, registry=REGISTRY, source="//trustos/referral-service")


def test_rows_for_serializes_event() -> None:
    metadata = sa.MetaData()
    table = make_outbox_table(metadata)
    referral_id = prefixed_uuid7("ref")
    event = ReferralSubmitted(referral_id=referral_id, campaign_id="cmp_x", occurred_at=NOW)

    (row,) = _writer(table).rows_for([event])

    assert row["id"] == event.event_id
    assert row["aggregate_type"] == "referral"
    assert row["aggregate_id"] == uuid_from_public_id(referral_id)
    assert row["event_type"] == "referral.referral.submitted.v1"
    payload = json.loads(row["payload"])
    assert payload["referral_id"] == referral_id
    assert row["headers"]["source"] == "//trustos/referral-service"


def test_unregistered_event_raises() -> None:
    @dataclass(frozen=True, slots=True, kw_only=True)
    class Mystery(DomainEvent):
        pass

    metadata = sa.MetaData()
    table = make_outbox_table(metadata)
    with pytest.raises(UnregisteredEventError):
        _writer(table).rows_for([Mystery(occurred_at=NOW)])


async def test_write_roundtrip_in_one_transaction() -> None:
    metadata = sa.MetaData()
    table = make_outbox_table(metadata)
    make_processed_events_table(metadata)
    engine = create_async_engine("sqlite+aiosqlite://")
    async with engine.begin() as conn:
        await conn.run_sync(metadata.create_all)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)

    writer = _writer(table)
    referral_id = prefixed_uuid7("ref")
    event = ReferralSubmitted(referral_id=referral_id, campaign_id="cmp_1", occurred_at=NOW)

    async with session_factory() as session:
        await writer.write(session, [event])
        await session.commit()

    async with session_factory() as session:
        rows = (await session.execute(sa.select(table))).mappings().all()
    assert len(rows) == 1
    assert rows[0]["event_type"] == "referral.referral.submitted.v1"
    assert json.loads(rows[0]["payload"])["campaign_id"] == "cmp_1"
    await engine.dispose()


async def test_write_with_no_events_is_noop() -> None:
    metadata = sa.MetaData()
    table = make_outbox_table(metadata)
    engine = create_async_engine("sqlite+aiosqlite://")
    async with engine.begin() as conn:
        await conn.run_sync(metadata.create_all)
    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    async with session_factory() as session:
        await _writer(table).write(session, [])
        await session.commit()
        count = (await session.execute(sa.select(sa.func.count()).select_from(table))).scalar()
    assert count == 0
    await engine.dispose()
