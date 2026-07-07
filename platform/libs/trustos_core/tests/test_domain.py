from dataclasses import dataclass
from datetime import UTC, datetime
from uuid import UUID

from trustos_core.domain import AggregateRoot, DomainEvent, event_payload


@dataclass(frozen=True, slots=True, kw_only=True)
class SomethingHappened(DomainEvent):
    subject_id: str


@dataclass(kw_only=True, eq=False)
class Widget(AggregateRoot):
    name: str

    def poke(self, now: datetime) -> None:
        self.record(SomethingHappened(subject_id=self.id, occurred_at=now))


NOW = datetime(2026, 7, 7, 12, 0, tzinfo=UTC)


def test_aggregate_collects_and_drains_events() -> None:
    widget = Widget(id="wgt_1", name="a")
    widget.poke(NOW)
    widget.poke(NOW)
    events = widget.collect_events()
    assert len(events) == 2
    assert all(isinstance(e, SomethingHappened) for e in events)
    assert widget.collect_events() == []  # drained


def test_domain_event_gets_unique_event_id() -> None:
    e1 = SomethingHappened(subject_id="x", occurred_at=NOW)
    e2 = SomethingHappened(subject_id="x", occurred_at=NOW)
    assert isinstance(e1.event_id, UUID)
    assert e1.event_id != e2.event_id


def test_entity_equality_is_identity_based() -> None:
    assert Widget(id="wgt_1", name="a") == Widget(id="wgt_1", name="b")
    assert Widget(id="wgt_1", name="a") != Widget(id="wgt_2", name="a")


def test_aggregate_version_defaults_to_zero() -> None:
    assert Widget(id="wgt_1", name="a").version == 0


def test_event_payload_serializes_datetimes_and_uuids() -> None:
    event = SomethingHappened(subject_id="wgt_1", occurred_at=NOW)
    payload = event_payload(event)
    assert payload["subject_id"] == "wgt_1"
    assert payload["occurred_at"] == "2026-07-07T12:00:00+00:00"
    assert payload["event_id"] == str(event.event_id)
