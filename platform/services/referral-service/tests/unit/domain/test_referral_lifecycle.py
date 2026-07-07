"""Domain state-machine tests: every allowed transition and every forbidden one
(03 §6 seam #1). Pure dataclasses, no mocks, no I/O."""

from __future__ import annotations

from datetime import UTC, datetime

import pytest
from helpers import make_scheme
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
from referral_service.domain.model.referral import _ALLOWED, Referral, ReferralStatus
from referral_service.domain.model.value_objects import CommissionScheme, TrustBand
from trustos_core.ids import prefixed_uuid7
from trustos_core.money import Currency, Money

NOW = datetime(2026, 7, 7, 10, 0, tzinfo=UTC)


def submit(
    *,
    scheme: CommissionScheme | None = None,
    band: TrustBand = TrustBand.SILVER,
    campaign_open: bool = True,
    referrer_id: str | None = None,
    prospect_owner_id: str | None = None,
) -> Referral:
    return Referral.submit(
        campaign_id=prefixed_uuid7("cmp"),
        referrer_id=referrer_id or prefixed_uuid7("usr"),
        referrer_band=band,
        prospect_contact_id=prefixed_uuid7("cnt"),
        prospect_owner_id=prospect_owner_id,
        org_id=prefixed_uuid7("org"),
        scheme=scheme or make_scheme(),
        campaign_open=campaign_open,
        now=NOW,
    )


def _force(referral: Referral, status: ReferralStatus) -> None:
    referral.status = status
    if status is ReferralStatus.CONVERTED:
        referral.commission = Money(1, Currency.INR)


def _invoke(referral: Referral, to: ReferralStatus) -> None:
    actions = {
        ReferralStatus.QUALIFIED: lambda: referral.qualify(qualified_by="org_x", now=NOW),
        ReferralStatus.CONVERTED: lambda: referral.convert(
            deal_id="dl_x", deal_value=Money(100_000, Currency.INR), now=NOW
        ),
        ReferralStatus.SETTLED: lambda: referral.mark_settled(now=NOW),
        ReferralStatus.REJECTED: lambda: referral.reject(reason="out of scope", now=NOW),
        ReferralStatus.EXPIRED: lambda: referral.expire(now=NOW),
    }
    actions[to]()


# ── submission guards ────────────────────────────────────────────────────────


def test_submit_raises_submitted_event() -> None:
    referral = submit()
    assert referral.status is ReferralStatus.SUBMITTED
    assert referral.id.startswith("ref_")
    events = referral.collect_events()
    assert len(events) == 1
    assert isinstance(events[0], ReferralSubmitted)
    assert events[0].referral_id == referral.id


def test_submit_rejects_closed_campaign() -> None:
    with pytest.raises(ReferralWindowClosed):
        submit(campaign_open=False)


def test_submit_rejects_self_referral() -> None:
    me = prefixed_uuid7("usr")
    with pytest.raises(InvalidReferralTransition, match="self-referral"):
        submit(referrer_id=me, prospect_owner_id=me)


def test_submit_gates_on_trust_band() -> None:
    scheme = make_scheme(min_band=TrustBand.GOLD)
    with pytest.raises(InsufficientTrustBand) as exc_info:
        submit(scheme=scheme, band=TrustBand.BRONZE)
    assert exc_info.value.required == TrustBand.GOLD
    assert exc_info.value.current == TrustBand.BRONZE
    # exact band is enough
    assert submit(scheme=scheme, band=TrustBand.GOLD).status is ReferralStatus.SUBMITTED


# ── full walk of the state machine ──────────────────────────────────────────


def test_every_allowed_transition() -> None:
    for from_status, allowed in _ALLOWED.items():
        for to_status in allowed:
            referral = submit()
            referral.collect_events()
            _force(referral, from_status)
            _invoke(referral, to_status)
            assert referral.status is to_status, f"{from_status} -> {to_status}"


def test_every_forbidden_transition() -> None:
    all_statuses = set(ReferralStatus)
    for from_status, allowed in _ALLOWED.items():
        for to_status in all_statuses - allowed - {ReferralStatus.SUBMITTED}:
            referral = submit()
            _force(referral, from_status)
            with pytest.raises(InvalidReferralTransition):
                _invoke(referral, to_status)


def test_terminal_states_allow_nothing() -> None:
    for terminal in (ReferralStatus.SETTLED, ReferralStatus.REJECTED, ReferralStatus.EXPIRED):
        assert _ALLOWED[terminal] == frozenset()


# ── behaviour details ───────────────────────────────────────────────────────


def test_happy_path_emits_events_in_order() -> None:
    referral = submit()
    referral.qualify(qualified_by="org_admin", now=NOW)
    referral.convert(deal_id="dl_1", deal_value=Money(250_000, Currency.INR), now=NOW)
    referral.mark_settled(now=NOW)
    events = referral.collect_events()
    assert [type(e) for e in events] == [
        ReferralSubmitted,
        ReferralQualified,
        ReferralConverted,
        CommissionSettled,
    ]


def test_convert_computes_rate_commission_from_snapshot() -> None:
    referral = submit(scheme=make_scheme(rate_basis_points=500))  # 5%
    referral.qualify(qualified_by="org_admin", now=NOW)
    referral.convert(deal_id="dl_1", deal_value=Money(250_000, Currency.INR), now=NOW)
    assert referral.commission == Money(12_500, Currency.INR)
    assert referral.converted_deal_id == "dl_1"
    converted = [e for e in referral.collect_events() if isinstance(e, ReferralConverted)]
    assert converted[0].commission_minor == 12_500
    assert converted[0].commission_currency is Currency.INR


def test_convert_with_fixed_scheme_needs_no_deal_value() -> None:
    referral = submit(scheme=make_scheme(fixed_minor=50_000))
    referral.qualify(qualified_by="org_admin", now=NOW)
    referral.convert(deal_id="dl_1", deal_value=None, now=NOW)
    assert referral.commission == Money(50_000, Currency.INR)


def test_rate_scheme_requires_deal_value() -> None:
    referral = submit(scheme=make_scheme(rate_basis_points=500))
    referral.qualify(qualified_by="org_admin", now=NOW)
    with pytest.raises(ValueError, match="verified deal value"):
        referral.convert(deal_id="dl_1", deal_value=None, now=NOW)


def test_referral_converts_at_most_once() -> None:
    referral = submit()
    referral.qualify(qualified_by="org_admin", now=NOW)
    referral.convert(deal_id="dl_1", deal_value=Money(100, Currency.INR), now=NOW)
    with pytest.raises(InvalidReferralTransition):
        referral.convert(deal_id="dl_2", deal_value=Money(100, Currency.INR), now=NOW)


def test_reject_records_reason() -> None:
    referral = submit()
    referral.reject(reason="prospect unreachable", now=NOW)
    assert referral.status is ReferralStatus.REJECTED
    assert referral.closed_reason == "prospect unreachable"
    rejected = [e for e in referral.collect_events() if isinstance(e, ReferralRejected)]
    assert rejected[0].reason == "prospect unreachable"


def test_expire_from_qualified() -> None:
    referral = submit()
    referral.qualify(qualified_by="org_admin", now=NOW)
    referral.expire(now=NOW)
    assert referral.status is ReferralStatus.EXPIRED
    assert isinstance(referral.collect_events()[-1], ReferralExpired)


def test_scheme_requires_exactly_one_of_fixed_or_rate() -> None:
    with pytest.raises(ValueError, match="exactly one"):
        CommissionScheme(fixed=None, rate_basis_points=None, min_referrer_band=TrustBand.STARTER)
    with pytest.raises(ValueError, match="exactly one"):
        CommissionScheme(
            fixed=Money(1, Currency.INR), rate_basis_points=100, min_referrer_band=TrustBand.STARTER
        )
