"""Application handler tests with in-memory fakes (03 §6 seam #2): asserting
"committed once, emitted <event>" needs zero infrastructure."""

from __future__ import annotations

import pytest
from fakes import FakeUnitOfWork, InMemoryStore, StubTrustGateway
from helpers import make_campaign, make_scheme
from referral_service.application.commands.convert_referral import (
    ConvertReferral,
    ConvertReferralHandler,
)
from referral_service.application.commands.qualify_referral import (
    QualifyReferral,
    QualifyReferralHandler,
)
from referral_service.application.commands.submit_referral import (
    SubmitReferral,
    SubmitReferralHandler,
)
from referral_service.application.errors import CampaignNotFound, DuplicateReferral, ReferralNotFound
from referral_service.domain.errors import InsufficientTrustBand, InvalidReferralTransition
from referral_service.domain.events import ReferralConverted, ReferralQualified, ReferralSubmitted
from referral_service.domain.model.campaign import CampaignStatus
from referral_service.domain.model.value_objects import TrustBand
from trustos_core.clock import FakeClock
from trustos_core.ids import prefixed_uuid7
from trustos_core.money import Currency, Money


@pytest.fixture
def store() -> InMemoryStore:
    return InMemoryStore()


def submit_handler(store: InMemoryStore, band: TrustBand = TrustBand.SILVER) -> SubmitReferralHandler:
    return SubmitReferralHandler(FakeUnitOfWork(store), StubTrustGateway(band), FakeClock())


def submit_cmd(campaign_id: str, prospect: str | None = None) -> SubmitReferral:
    return SubmitReferral(
        campaign_id=campaign_id,
        prospect_contact_id=prospect or prefixed_uuid7("cnt"),
        prospect_owner_id=None,
        actor_type="user",
        actor_id=prefixed_uuid7("usr"),
    )


# ── SubmitReferral ──────────────────────────────────────────────────────────


async def test_submit_persists_and_outboxes_atomically(store: InMemoryStore) -> None:
    campaign = make_campaign()
    store.campaigns[campaign.id] = campaign

    result = await submit_handler(store).handle(submit_cmd(campaign.id))

    assert result.status == "submitted"
    assert result.referral_id in store.referrals
    assert store.commits == 1
    assert len(store.outbox) == 1
    event = store.outbox[0]
    assert isinstance(event, ReferralSubmitted)
    assert event.referral_id == result.referral_id
    assert event.org_id == campaign.org_id


async def test_submit_snapshots_scheme_at_submission(store: InMemoryStore) -> None:
    campaign = make_campaign(scheme=make_scheme(rate_basis_points=750))
    store.campaigns[campaign.id] = campaign
    result = await submit_handler(store).handle(submit_cmd(campaign.id))
    assert result.scheme_rate_basis_points == 750
    assert store.referrals[result.referral_id].scheme_snapshot.rate_basis_points == 750


async def test_submit_unknown_campaign(store: InMemoryStore) -> None:
    with pytest.raises(CampaignNotFound):
        await submit_handler(store).handle(submit_cmd("cmp_missing"))
    assert store.commits == 0


async def test_submit_duplicate_prospect_conflicts(store: InMemoryStore) -> None:
    campaign = make_campaign()
    store.campaigns[campaign.id] = campaign
    prospect = prefixed_uuid7("cnt")
    first = await submit_handler(store).handle(submit_cmd(campaign.id, prospect))
    with pytest.raises(DuplicateReferral) as exc_info:
        await submit_handler(store).handle(submit_cmd(campaign.id, prospect))
    assert exc_info.value.existing_referral_id == first.referral_id
    assert store.commits == 1  # second command never committed


async def test_submit_band_gate_propagates(store: InMemoryStore) -> None:
    campaign = make_campaign(scheme=make_scheme(min_band=TrustBand.GOLD))
    store.campaigns[campaign.id] = campaign
    with pytest.raises(InsufficientTrustBand):
        await submit_handler(store, band=TrustBand.BRONZE).handle(submit_cmd(campaign.id))
    assert store.referrals == {}


async def test_submit_draft_campaign_is_closed(store: InMemoryStore) -> None:
    campaign = make_campaign(status=CampaignStatus.DRAFT)
    store.campaigns[campaign.id] = campaign
    from referral_service.domain.errors import ReferralWindowClosed

    with pytest.raises(ReferralWindowClosed):
        await submit_handler(store).handle(submit_cmd(campaign.id))


# ── QualifyReferral / ConvertReferral ───────────────────────────────────────


async def _submitted(store: InMemoryStore) -> str:
    campaign = make_campaign()
    store.campaigns[campaign.id] = campaign
    result = await submit_handler(store).handle(submit_cmd(campaign.id))
    return result.referral_id


async def test_qualify_transitions_and_outboxes(store: InMemoryStore) -> None:
    referral_id = await _submitted(store)
    handler = QualifyReferralHandler(FakeUnitOfWork(store), FakeClock())

    result = await handler.handle(
        QualifyReferral(referral_id=referral_id, actor_type="org", actor_id="org_admin")
    )

    assert result.status == "qualified"
    assert store.referrals[referral_id].status.value == "qualified"
    qualified = [e for e in store.outbox if isinstance(e, ReferralQualified)]
    assert len(qualified) == 1
    assert qualified[0].qualified_by == "org_admin"


async def test_qualify_missing_referral(store: InMemoryStore) -> None:
    handler = QualifyReferralHandler(FakeUnitOfWork(store), FakeClock())
    with pytest.raises(ReferralNotFound):
        await handler.handle(QualifyReferral(referral_id="ref_x", actor_type="org", actor_id="o"))


async def test_convert_computes_commission_and_outboxes(store: InMemoryStore) -> None:
    referral_id = await _submitted(store)
    await QualifyReferralHandler(FakeUnitOfWork(store), FakeClock()).handle(
        QualifyReferral(referral_id=referral_id, actor_type="org", actor_id="o")
    )

    result = await ConvertReferralHandler(FakeUnitOfWork(store), FakeClock()).handle(
        ConvertReferral(
            referral_id=referral_id,
            deal_id=prefixed_uuid7("dl"),
            deal_value=Money(250_000, Currency.INR),
            actor_type="system",
            actor_id="deal-consumer",
        )
    )

    assert result.status == "converted"
    assert result.commission_minor == 12_500  # 5% default scheme
    assert result.commission_currency == "INR"
    converted = [e for e in store.outbox if isinstance(e, ReferralConverted)]
    assert len(converted) == 1


async def test_convert_before_qualify_is_invalid(store: InMemoryStore) -> None:
    referral_id = await _submitted(store)
    with pytest.raises(InvalidReferralTransition):
        await ConvertReferralHandler(FakeUnitOfWork(store), FakeClock()).handle(
            ConvertReferral(
                referral_id=referral_id,
                deal_id="dl_1",
                deal_value=Money(1, Currency.INR),
                actor_type="system",
                actor_id="s",
            )
        )
