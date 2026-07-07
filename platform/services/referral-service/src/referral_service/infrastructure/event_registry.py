"""Domain event -> wire mapping for the outbox (03 §2.3: the serde owns translation).

Event types follow the taxonomy ``referral.<aggregate>.<verb-past>.v<N>``
(shared-context §3); partition key = referral public id (per-aggregate ordering).
"""

from __future__ import annotations

from trustos_core.domain import DomainEvent
from trustos_core.outbox import EventMeta

from referral_service.domain.events import (
    CommissionSettled,
    ReferralConverted,
    ReferralExpired,
    ReferralQualified,
    ReferralRejected,
    ReferralSubmitted,
)


def _referral_id(event: DomainEvent) -> str:
    referral_id = getattr(event, "referral_id", None)
    assert isinstance(referral_id, str)
    return referral_id


def _meta(event_type: str) -> EventMeta:
    return EventMeta(event_type=event_type, aggregate_type="referral", aggregate_id=_referral_id)


EVENT_REGISTRY: dict[type[DomainEvent], EventMeta] = {
    ReferralSubmitted: _meta("referral.referral.submitted.v1"),
    ReferralQualified: _meta("referral.referral.qualified.v1"),
    ReferralConverted: _meta("referral.referral.converted.v1"),
    CommissionSettled: _meta("referral.commission.settled.v1"),
    ReferralRejected: _meta("referral.referral.rejected.v1"),
    ReferralExpired: _meta("referral.referral.expired.v1"),
}
