"""SubmitReferral command handler (03 §2.5 — the exemplar command handler).

Handlers are thin: load, invoke aggregate, commit. All I/O behind ports.
"""

from __future__ import annotations

from dataclasses import dataclass

from trustos_core.clock import Clock, SystemClock

from referral_service.application.errors import CampaignNotFound, DuplicateReferral
from referral_service.application.ports.trust_gateway import TrustGateway
from referral_service.application.ports.unit_of_work import UnitOfWork
from referral_service.domain.model.referral import Referral
from referral_service.domain.model.value_objects import TrustBand


@dataclass(frozen=True, slots=True)
class SubmitReferral:
    """Command DTO. actor_* per shared-context tenancy model."""

    campaign_id: str
    prospect_contact_id: str
    prospect_owner_id: str | None
    actor_type: str  # "user" — referrals are personal even when campaign is org-owned
    actor_id: str    # referrer "usr_..."


@dataclass(frozen=True, slots=True)
class SubmitReferralResult:
    referral_id: str
    status: str
    scheme_fixed_minor: int | None
    scheme_fixed_currency: str | None
    scheme_rate_basis_points: int | None
    scheme_min_referrer_band: str
    submitted_at_iso: str


class SubmitReferralHandler:
    def __init__(self, uow: UnitOfWork, trust: TrustGateway, clock: Clock | None = None) -> None:
        self._uow = uow
        self._trust = trust
        self._clock = clock or SystemClock()

    async def handle(self, cmd: SubmitReferral) -> SubmitReferralResult:
        # cross-service read BEFORE the transaction (never hold a DB tx across a network call)
        band: TrustBand = await self._trust.get_band(cmd.actor_id)
        now = self._clock.now()

        async with self._uow as uow:
            campaign = await uow.campaigns.get(cmd.campaign_id)
            if campaign is None:
                raise CampaignNotFound(cmd.campaign_id)

            existing = await uow.referrals.find_open_by_prospect(
                cmd.campaign_id, cmd.prospect_contact_id
            )
            if existing is not None:
                raise DuplicateReferral(existing.id)  # 409 + existing id in Problem Details

            referral = Referral.submit(
                campaign_id=campaign.id,
                referrer_id=cmd.actor_id,
                referrer_band=band,
                prospect_contact_id=cmd.prospect_contact_id,
                prospect_owner_id=cmd.prospect_owner_id,
                org_id=campaign.org_id,
                scheme=campaign.scheme,
                campaign_open=campaign.is_open(now=now),
                now=now,
            )
            uow.referrals.add(referral)
            await uow.commit()  # referral row + outbox(referral.referral.submitted.v1) atomically

        scheme = referral.scheme_snapshot
        return SubmitReferralResult(
            referral_id=referral.id,
            status=referral.status,
            scheme_fixed_minor=scheme.fixed.amount_minor if scheme.fixed else None,
            scheme_fixed_currency=scheme.fixed.currency if scheme.fixed else None,
            scheme_rate_basis_points=scheme.rate_basis_points,
            scheme_min_referrer_band=scheme.min_referrer_band,
            submitted_at_iso=referral.submitted_at.isoformat(),
        )
