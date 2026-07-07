"""Domain events raised by the Referral aggregate (03 §2.3).

Frozen, past-tense, aggregate-scoped facts. They map 1:1 to the Kafka taxonomy
(``referral.referral.submitted.v1`` etc.) but the domain layer knows nothing
about Kafka/CloudEvents — infrastructure owns that translation.
"""

from __future__ import annotations

from dataclasses import dataclass

from trustos_core.domain import DomainEvent
from trustos_core.money import Currency


@dataclass(frozen=True, slots=True, kw_only=True)
class ReferralSubmitted(DomainEvent):
    referral_id: str
    campaign_id: str
    referrer_id: str
    org_id: str
    # wire: topic trustos.referral.referral, type referral.referral.submitted.v1


@dataclass(frozen=True, slots=True, kw_only=True)
class ReferralQualified(DomainEvent):
    referral_id: str
    campaign_id: str
    referrer_id: str
    qualified_by: str  # actor id — org member or system rule


@dataclass(frozen=True, slots=True, kw_only=True)
class ReferralConverted(DomainEvent):
    referral_id: str
    campaign_id: str
    referrer_id: str
    deal_id: str
    commission_minor: int
    commission_currency: Currency


@dataclass(frozen=True, slots=True, kw_only=True)
class CommissionSettled(DomainEvent):
    """wire: referral.commission.settled.v1 — drives trust factor + rewards XP."""

    referral_id: str
    campaign_id: str
    referrer_id: str
    commission_minor: int
    commission_currency: Currency


@dataclass(frozen=True, slots=True, kw_only=True)
class ReferralRejected(DomainEvent):
    referral_id: str
    campaign_id: str
    referrer_id: str
    reason: str


@dataclass(frozen=True, slots=True, kw_only=True)
class ReferralExpired(DomainEvent):
    referral_id: str
    campaign_id: str
    referrer_id: str
