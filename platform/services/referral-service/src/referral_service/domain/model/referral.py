"""Referral aggregate root (03 §2.2).

The aggregate is the ONLY consistency boundary: one referral == one transaction.
State machine enforced in the aggregate, never in handlers or SQL. Events are
collected on the instance and drained by the Unit of Work into the outbox — the
aggregate never talks to Kafka.

State machine (05-data-architecture.md §3.5, sans the optional ``contacted`` hop):

    submitted ──► qualified ──► converted ──► settled
        │             │
        └──► rejected/expired ◄┘        (terminal: settled, rejected, expired)
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

from trustos_core.domain import AggregateRoot
from trustos_core.ids import prefixed_uuid7

from referral_service.domain.errors import (
    InsufficientTrustBand,
    InvalidReferralTransition,
    ReferralWindowClosed,
)
from referral_service.domain.events import (
    CommissionSettled,
    ReferralConverted,
    ReferralExpired,
    ReferralQualified,
    ReferralRejected,
    ReferralSubmitted,
)
from referral_service.domain.model.value_objects import CommissionScheme, Money, TrustBand


class ReferralStatus(StrEnum):
    SUBMITTED = "submitted"
    QUALIFIED = "qualified"    # prospect verified real & in-scope
    CONVERTED = "converted"    # linked deal won -> commission computable
    SETTLED = "settled"        # ledger posted (settlement saga)
    REJECTED = "rejected"
    EXPIRED = "expired"


_ALLOWED: dict[ReferralStatus, frozenset[ReferralStatus]] = {
    ReferralStatus.SUBMITTED: frozenset(
        {ReferralStatus.QUALIFIED, ReferralStatus.REJECTED, ReferralStatus.EXPIRED}
    ),
    ReferralStatus.QUALIFIED: frozenset(
        {ReferralStatus.CONVERTED, ReferralStatus.REJECTED, ReferralStatus.EXPIRED}
    ),
    ReferralStatus.CONVERTED: frozenset({ReferralStatus.SETTLED}),
    ReferralStatus.SETTLED: frozenset(),
    ReferralStatus.REJECTED: frozenset(),
    ReferralStatus.EXPIRED: frozenset(),
}


@dataclass(kw_only=True, eq=False)
class Referral(AggregateRoot):
    """Aggregate root. Invariants:
    - transitions only along _ALLOWED
    - a referral converts at most once, settles at most once
    - commission derives from the campaign scheme captured AT SUBMISSION (schemes may change later)
    - self-referrals are structurally impossible (checked at construction)
    """

    campaign_id: str                          # "cmp_..."
    referrer_id: str                          # "usr_..."
    prospect_contact_id: str                  # contact-service ref, PII stays there
    org_id: str                               # campaign owner "org_..."
    scheme_snapshot: CommissionScheme
    status: ReferralStatus
    submitted_at: datetime
    converted_deal_id: str | None = None
    commission: Money | None = None
    qualified_at: datetime | None = None
    converted_at: datetime | None = None
    settled_at: datetime | None = None
    closed_reason: str | None = None

    # ---- factory --------------------------------------------------------

    @classmethod
    def submit(
        cls,
        *,
        campaign_id: str,
        referrer_id: str,
        referrer_band: TrustBand,
        prospect_contact_id: str,
        prospect_owner_id: str | None,
        org_id: str,
        scheme: CommissionScheme,
        campaign_open: bool,
        now: datetime,
    ) -> Referral:
        if not campaign_open:
            raise ReferralWindowClosed(campaign_id)
        if prospect_owner_id is not None and referrer_id == prospect_owner_id:
            raise InvalidReferralTransition("self-referral is not allowed")
        if not referrer_band >= scheme.min_referrer_band:
            raise InsufficientTrustBand(required=scheme.min_referrer_band, current=referrer_band)
        referral = cls(
            id=prefixed_uuid7("ref"),
            campaign_id=campaign_id,
            referrer_id=referrer_id,
            prospect_contact_id=prospect_contact_id,
            org_id=org_id,
            scheme_snapshot=scheme,
            status=ReferralStatus.SUBMITTED,
            submitted_at=now,
        )
        referral.record(
            ReferralSubmitted(
                referral_id=referral.id,
                campaign_id=campaign_id,
                referrer_id=referrer_id,
                org_id=org_id,
                occurred_at=now,
            )
        )
        return referral

    # ---- behaviour ------------------------------------------------------

    def qualify(self, *, qualified_by: str, now: datetime) -> None:
        self._transition(ReferralStatus.QUALIFIED)
        self.qualified_at = now
        self.record(
            ReferralQualified(
                referral_id=self.id,
                referrer_id=self.referrer_id,
                campaign_id=self.campaign_id,
                qualified_by=qualified_by,
                occurred_at=now,
            )
        )

    def convert(self, *, deal_id: str, deal_value: Money | None, now: datetime) -> None:
        self._transition(ReferralStatus.CONVERTED)
        self.converted_deal_id = deal_id
        self.converted_at = now
        self.commission = self.scheme_snapshot.commission_for(deal_value)
        self.record(
            ReferralConverted(
                referral_id=self.id,
                referrer_id=self.referrer_id,
                campaign_id=self.campaign_id,
                deal_id=deal_id,
                commission_minor=self.commission.amount_minor,
                commission_currency=self.commission.currency,
                occurred_at=now,
            )
        )

    def mark_settled(self, *, now: datetime) -> None:
        """Terminal transition, invoked only by the settlement saga after ledger posting."""
        self._transition(ReferralStatus.SETTLED)
        self.settled_at = now
        assert self.commission is not None  # guaranteed: settled only follows converted
        self.record(
            CommissionSettled(
                referral_id=self.id,
                referrer_id=self.referrer_id,
                campaign_id=self.campaign_id,
                commission_minor=self.commission.amount_minor,
                commission_currency=self.commission.currency,
                occurred_at=now,
            )
        )

    def reject(self, *, reason: str, now: datetime) -> None:
        self._transition(ReferralStatus.REJECTED)
        self.closed_reason = reason
        self.record(
            ReferralRejected(
                referral_id=self.id,
                referrer_id=self.referrer_id,
                campaign_id=self.campaign_id,
                reason=reason,
                occurred_at=now,
            )
        )

    def expire(self, *, now: datetime) -> None:
        self._transition(ReferralStatus.EXPIRED)
        self.closed_reason = "expired"
        self.record(
            ReferralExpired(
                referral_id=self.id,
                referrer_id=self.referrer_id,
                campaign_id=self.campaign_id,
                occurred_at=now,
            )
        )

    # ---- plumbing -------------------------------------------------------

    def _transition(self, to: ReferralStatus) -> None:
        if to not in _ALLOWED[self.status]:
            raise InvalidReferralTransition(f"{self.status} -> {to} not allowed for {self.id}")
        self.status = to
