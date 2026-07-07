"""Transactional outbox (shared-context §1; 05-data-architecture.md §2.3).

Business rows and outbox rows commit in ONE local transaction; Debezium tails
the WAL and publishes to Kafka. ``OutboxWriter`` serializes domain events into
``outbox_events`` rows inside the Unit of Work's session/transaction.

Payloads here are JSON bytes; the protobuf/Schema-Registry codec plugs in via a
custom ``serializer`` once ``contracts/gen`` lands.
"""

from __future__ import annotations

import json
from collections.abc import Callable, Iterable, Mapping
from dataclasses import dataclass
from typing import Any
from uuid import UUID

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import JSONB
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from sqlalchemy.ext.asyncio import AsyncSession

from trustos_core.domain import DomainEvent, event_payload
from trustos_core.ids import InvalidPublicIdError, uuid_from_public_id


def make_outbox_table(metadata: sa.MetaData) -> sa.Table:
    """The ``outbox_events`` table, identical in every service database (05 §2.3)."""
    return sa.Table(
        "outbox_events",
        metadata,
        sa.Column("id", PG_UUID(as_uuid=True).with_variant(sa.Uuid(), "sqlite"), primary_key=True),
        sa.Column("aggregate_type", sa.Text, nullable=False),
        sa.Column("aggregate_id", PG_UUID(as_uuid=True).with_variant(sa.Uuid(), "sqlite"), nullable=False),
        sa.Column("event_type", sa.Text, nullable=False),
        sa.Column("payload", sa.LargeBinary, nullable=False),
        sa.Column(
            "headers",
            JSONB().with_variant(sa.JSON(), "sqlite"),
            nullable=False,
            server_default=sa.text("'{}'"),
        ),
        sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
        sa.Index("outbox_events_created_at_idx", "created_at"),
    )


def make_processed_events_table(metadata: sa.MetaData) -> sa.Table:
    """Consumer-side dedup table (03 §4.2): PK (event_id, consumer_group)."""
    return sa.Table(
        "processed_events",
        metadata,
        sa.Column("event_id", PG_UUID(as_uuid=True).with_variant(sa.Uuid(), "sqlite"), primary_key=True),
        sa.Column("consumer_group", sa.Text, primary_key=True),
        sa.Column("processed_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
    )


@dataclass(frozen=True, slots=True)
class EventMeta:
    """How a domain-event class maps onto the wire (03 §2.3: serde owns translation).

    ``event_type`` follows the taxonomy ``<domain>.<aggregate>.<verb-past>.v<N>``;
    ``aggregate_id`` extracts the partition key (a prefixed public ID or raw UUID).
    """

    event_type: str
    aggregate_type: str
    aggregate_id: Callable[[DomainEvent], str]


def _as_uuid(key: str) -> UUID:
    try:
        return uuid_from_public_id(key)
    except InvalidPublicIdError:
        return UUID(key)


class OutboxWriter:
    """Serializes drained aggregate events into outbox rows in the caller's session."""

    def __init__(
        self,
        *,
        table: sa.Table,
        registry: Mapping[type[DomainEvent], EventMeta],
        source: str,
        serializer: Callable[[DomainEvent], bytes] | None = None,
    ) -> None:
        self._table = table
        self._registry = dict(registry)
        self._source = source
        self._serializer = serializer or self._json_serializer

    @staticmethod
    def _json_serializer(event: DomainEvent) -> bytes:
        return json.dumps(event_payload(event), sort_keys=True).encode()

    def rows_for(self, events: Iterable[DomainEvent]) -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []
        for event in events:
            try:
                meta = self._registry[type(event)]
            except KeyError:
                raise UnregisteredEventError(type(event).__name__) from None
            rows.append(
                {
                    "id": event.event_id,
                    "aggregate_type": meta.aggregate_type,
                    "aggregate_id": _as_uuid(meta.aggregate_id(event)),
                    "event_type": meta.event_type,
                    "payload": self._serializer(event),
                    "headers": {"source": self._source, "event_id": str(event.event_id)},
                }
            )
        return rows

    async def write(self, session: AsyncSession, events: Iterable[DomainEvent]) -> None:
        rows = self.rows_for(events)
        if rows:
            await session.execute(sa.insert(self._table), rows)


class UnregisteredEventError(LookupError):
    def __init__(self, event_name: str) -> None:
        super().__init__(f"no EventMeta registered for domain event {event_name}")
