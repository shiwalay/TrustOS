"""Aggregate <-> row mappers (03 §2.4): no ORM classes in the domain.

Public IDs on the wire/domain ("ref_...", "cmp_...") are prefix + base62 of the
row UUID (05 §2.1), so mapping is a pure, reversible transform.
"""

from __future__ import annotations

import hashlib
from collections.abc import Mapping
from typing import Any
from uuid import UUID

from trustos_core.ids import InvalidPublicIdError, public_id, uuid_from_public_id
from trustos_core.money import Currency, Money

from referral_service.domain.model.campaign import CampaignStatus, ReferralCampaign
from referral_service.domain.model.referral import Referral, ReferralStatus
from referral_service.domain.model.value_objects import CommissionScheme, TrustBand

PREFIX_REFERRAL = "ref"
PREFIX_CAMPAIGN = "cmp"
PREFIX_USER = "usr"
PREFIX_ORG = "org"
PREFIX_CONTACT = "cnt"
PREFIX_DEAL = "dl"


def to_uuid(value: str) -> UUID:
    """Public ID ('ref_...') or raw UUID string -> UUID."""
    try:
        return uuid_from_public_id(value)
    except InvalidPublicIdError:
        return UUID(value)


def prospect_identity_hash(prospect_contact_id: str) -> bytes:
    """Blind index of the prospect reference (05 §2.1: equality lookup, no PII)."""
    return hashlib.sha256(prospect_contact_id.encode()).digest()


# ── commission scheme <-> jsonb ─────────────────────────────────────────────


def scheme_to_json(scheme: CommissionScheme) -> dict[str, Any]:
    return {
        "fixed_minor": scheme.fixed.amount_minor if scheme.fixed else None,
        "fixed_currency": scheme.fixed.currency if scheme.fixed else None,
        "rate_basis_points": scheme.rate_basis_points,
        "min_referrer_band": scheme.min_referrer_band,
    }


def scheme_from_json(doc: Mapping[str, Any]) -> CommissionScheme:
    fixed = None
    if doc.get("fixed_minor") is not None:
        fixed = Money(int(doc["fixed_minor"]), Currency(doc["fixed_currency"]))
    rate = doc.get("rate_basis_points")
    return CommissionScheme(
        fixed=fixed,
        rate_basis_points=int(rate) if rate is not None else None,
        min_referrer_band=TrustBand(doc["min_referrer_band"]),
    )


def scheme_from_commission_plan(
    *, plan_type: str, config: Mapping[str, Any], currency: str, min_referrer_band: str | None
) -> CommissionScheme:
    """Translate a commission_plans row (05 §3.5) into the domain scheme.

    ``flat`` and ``percent`` are live; ``tiered``/``hybrid`` plans need the tier
    ladder engine (06-algorithms.md) and are rejected loudly until it lands.
    """
    band = TrustBand(min_referrer_band) if min_referrer_band else TrustBand.STARTER
    if plan_type == "flat":
        return CommissionScheme(
            fixed=Money(int(config["amount_minor"]), Currency(currency)),
            rate_basis_points=None,
            min_referrer_band=band,
        )
    if plan_type == "percent":
        return CommissionScheme(
            fixed=None,
            rate_basis_points=round(float(config["percent"]) * 100),
            min_referrer_band=band,
        )
    raise ValueError(f"commission plan_type {plan_type!r} is not supported yet")


# ── referral ────────────────────────────────────────────────────────────────


def referral_to_row(referral: Referral) -> dict[str, Any]:
    commission = referral.commission
    return {
        "id": uuid_from_public_id(referral.id, expected_prefix=PREFIX_REFERRAL),
        "public_id": referral.id,
        "campaign_id": to_uuid(referral.campaign_id),
        "org_id": to_uuid(referral.org_id),
        "referrer_user_id": to_uuid(referral.referrer_id),
        "prospect_contact_id": to_uuid(referral.prospect_contact_id),
        "prospect_identity_hash": prospect_identity_hash(referral.prospect_contact_id),
        "scheme_snapshot": scheme_to_json(referral.scheme_snapshot),
        "state": referral.status.value,
        "deal_id": to_uuid(referral.converted_deal_id) if referral.converted_deal_id else None,
        "commission_minor": commission.amount_minor if commission else None,
        "commission_currency": commission.currency.value if commission else None,
        "submitted_at": referral.submitted_at,
        "qualified_at": referral.qualified_at,
        "converted_at": referral.converted_at,
        "settled_at": referral.settled_at,
        "closed_reason": referral.closed_reason,
    }


def referral_from_row(row: Mapping[str, Any]) -> Referral:
    commission = None
    if row["commission_minor"] is not None:
        commission = Money(row["commission_minor"], Currency(row["commission_currency"]))
    return Referral(
        id=row["public_id"],
        campaign_id=public_id(PREFIX_CAMPAIGN, row["campaign_id"]),
        referrer_id=public_id(PREFIX_USER, row["referrer_user_id"]),
        prospect_contact_id=public_id(PREFIX_CONTACT, row["prospect_contact_id"]),
        org_id=public_id(PREFIX_ORG, row["org_id"]),
        scheme_snapshot=scheme_from_json(row["scheme_snapshot"]),
        status=ReferralStatus(row["state"]),
        submitted_at=row["submitted_at"],
        version=row["version"],
        converted_deal_id=public_id(PREFIX_DEAL, row["deal_id"]) if row["deal_id"] else None,
        commission=commission,
        qualified_at=row["qualified_at"],
        converted_at=row["converted_at"],
        settled_at=row["settled_at"],
        closed_reason=row["closed_reason"],
    )


# ── campaign ────────────────────────────────────────────────────────────────


def campaign_from_row(campaign_row: Mapping[str, Any], plan_row: Mapping[str, Any]) -> ReferralCampaign:
    return ReferralCampaign(
        id=campaign_row["public_id"],
        org_id=public_id(PREFIX_ORG, campaign_row["org_id"]),
        title=campaign_row["title"],
        scheme=scheme_from_commission_plan(
            plan_type=plan_row["plan_type"],
            config=plan_row["config"],
            currency=plan_row["currency"],
            min_referrer_band=campaign_row["min_referrer_band"],
        ),
        status=CampaignStatus(campaign_row["status"]),
        starts_at=campaign_row["starts_at"],
        ends_at=campaign_row["ends_at"],
    )
