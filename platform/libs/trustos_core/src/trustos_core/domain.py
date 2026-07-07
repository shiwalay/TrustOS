"""DDD building blocks: DomainEvent, ValueObject, Entity, AggregateRoot.

Aggregates collect domain events on the instance; the Unit of Work drains them
into the transactional outbox (03-backend-architecture.md §2.2/§2.4). Aggregates
never talk to Kafka.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any
from uuid import UUID, uuid4


@dataclass(frozen=True, slots=True, kw_only=True)
class DomainEvent:
    """Frozen, past-tense, aggregate-scoped fact (03 §2.3)."""

    event_id: UUID = field(default_factory=uuid4)
    occurred_at: datetime


@dataclass(frozen=True, slots=True)
class ValueObject:
    """Base for immutable value objects.

    Subclass as ``@dataclass(frozen=True, slots=True)``; equality and hashing
    come from dataclass field semantics (structural equality, no identity).
    """


@dataclass(kw_only=True, eq=False)
class Entity:
    """Identity-equality object. ``id`` is the prefixed public ID (e.g. ``ref_...``)."""

    id: str

    def __eq__(self, other: object) -> bool:
        if not isinstance(other, Entity):
            return NotImplemented
        return type(self) is type(other) and self.id == other.id

    def __hash__(self) -> int:
        return hash((type(self), self.id))


@dataclass(kw_only=True, eq=False)
class AggregateRoot(Entity):
    """Consistency boundary: one aggregate == one transaction (03 §2.2).

    ``version`` backs optimistic concurrency in repositories; ``record()``ed
    events are drained by ``collect_events()`` (called by the UoW at commit).
    """

    version: int = 0
    _events: list[DomainEvent] = field(default_factory=list, repr=False)

    def record(self, event: DomainEvent) -> None:
        self._events.append(event)

    def collect_events(self) -> list[DomainEvent]:
        events, self._events = self._events, []
        return events


def event_payload(event: DomainEvent) -> dict[str, Any]:
    """Flat, JSON-friendly dict of an event's fields (for outbox serialization)."""
    payload: dict[str, Any] = {}
    for name in event.__dataclass_fields__:
        value = getattr(event, name)
        if isinstance(value, datetime):
            value = value.isoformat()
        elif isinstance(value, UUID):
            value = str(value)
        payload[name] = value
    return payload
