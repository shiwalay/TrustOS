"""Shared test builders."""

from __future__ import annotations

from datetime import UTC, datetime

from referral_service.domain.model.campaign import CampaignStatus, ReferralCampaign
from referral_service.domain.model.value_objects import CommissionScheme, TrustBand
from trustos_core.ids import prefixed_uuid7
from trustos_core.money import Currency, Money

NOW = datetime(2026, 7, 7, 10, 0, tzinfo=UTC)


def make_scheme(
    *,
    fixed_minor: int | None = None,
    rate_basis_points: int | None = 500,
    min_band: TrustBand = TrustBand.STARTER,
) -> CommissionScheme:
    fixed = Money(fixed_minor, Currency.INR) if fixed_minor is not None else None
    return CommissionScheme(
        fixed=fixed,
        rate_basis_points=None if fixed is not None else rate_basis_points,
        min_referrer_band=min_band,
    )


def make_campaign(
    *,
    scheme: CommissionScheme | None = None,
    status: CampaignStatus = CampaignStatus.PUBLISHED,
    org_id: str | None = None,
) -> ReferralCampaign:
    return ReferralCampaign(
        id=prefixed_uuid7("cmp"),
        org_id=org_id or prefixed_uuid7("org"),
        title="GST software referrals",
        scheme=scheme or make_scheme(),
        status=status,
    )
