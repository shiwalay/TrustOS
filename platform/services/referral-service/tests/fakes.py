"""In-memory fakes implementing the application ports — zero I/O (03 §6).

Same composition-root shape as production (di.Container), fakes swapped in;
no monkeypatching, ever.
"""

from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from types import TracebackType

from referral_service.application.ports.read_model import ReferralView
from referral_service.di import Container
from referral_service.domain.model.campaign import ReferralCampaign
from referral_service.domain.model.referral import Referral, ReferralStatus
from referral_service.domain.model.value_objects import TrustBand
from referral_service.settings import Settings
from trustos_core.clock import Clock, FakeClock
from trustos_core.domain import DomainEvent
from trustos_core.idempotency import InMemoryIdempotencyBackend


@dataclass
class InMemoryStore:
    """Shared state behind the fake repos/read model (one 'database')."""

    referrals: dict[str, Referral] = field(default_factory=dict)
    campaigns: dict[str, ReferralCampaign] = field(default_factory=dict)
    outbox: list[DomainEvent] = field(default_factory=list)
    commits: int = 0


class InMemoryReferralRepository:
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store
        self.seen: dict[str, Referral] = {}

    async def get(self, referral_id: str) -> Referral | None:
        referral = self._store.referrals.get(referral_id)
        if referral is not None:
            self.seen[referral.id] = referral
        return referral

    async def get_for_update(self, referral_id: str) -> Referral | None:
        return await self.get(referral_id)

    async def find_open_by_prospect(
        self, campaign_id: str, prospect_contact_id: str
    ) -> Referral | None:
        for referral in self._store.referrals.values():
            if (
                referral.campaign_id == campaign_id
                and referral.prospect_contact_id == prospect_contact_id
                and referral.status not in (ReferralStatus.REJECTED, ReferralStatus.EXPIRED)
            ):
                return referral
        return None

    def add(self, referral: Referral) -> None:
        self.seen[referral.id] = referral
        self._store.referrals[referral.id] = referral


class InMemoryCampaignRepository:
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store

    async def get(self, campaign_id: str) -> ReferralCampaign | None:
        return self._store.campaigns.get(campaign_id)


class FakeUnitOfWork:
    """Captures drained aggregate events as the 'outbox' (03 §6 seam #2)."""

    def __init__(self, store: InMemoryStore) -> None:
        self._store = store
        self.referrals = InMemoryReferralRepository(store)
        self.campaigns = InMemoryCampaignRepository(store)

    async def __aenter__(self) -> FakeUnitOfWork:
        return self

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        tb: TracebackType | None,
    ) -> None:
        return None

    async def commit(self) -> None:
        for referral in self.referrals.seen.values():
            self._store.outbox.extend(referral.collect_events())
        self._store.commits += 1

    async def rollback(self) -> None:
        return None


class InMemoryReferralReadModel:
    def __init__(self, store: InMemoryStore) -> None:
        self._store = store

    @staticmethod
    def _to_view(referral: Referral) -> ReferralView:
        commission = referral.commission
        return ReferralView(
            id=referral.id,
            campaign_id=referral.campaign_id,
            referrer_id=referral.referrer_id,
            status=referral.status.value,
            submitted_at=referral.submitted_at,
            converted_deal_id=referral.converted_deal_id,
            commission_minor=commission.amount_minor if commission else None,
            commission_currency=commission.currency.value if commission else None,
        )

    async def get(self, referral_id: str) -> ReferralView | None:
        referral = self._store.referrals.get(referral_id)
        return self._to_view(referral) if referral else None

    async def list(
        self,
        *,
        statuses: tuple[str, ...] | None,
        after: tuple[datetime, str] | None,
        limit: int,
    ) -> list[ReferralView]:
        rows = [
            self._to_view(r)
            for r in self._store.referrals.values()
            if statuses is None or r.status.value in statuses
        ]
        rows.sort(key=lambda v: (v.submitted_at, v.id), reverse=True)
        if after is not None:
            rows = [v for v in rows if (v.submitted_at, v.id) < after]
        return rows[:limit]


class StubTrustGateway:
    def __init__(self, band: TrustBand = TrustBand.SILVER) -> None:
        self.band = band

    async def get_band(self, user_id: str) -> TrustBand:
        return self.band


def build_test_container(
    store: InMemoryStore,
    *,
    band: TrustBand = TrustBand.SILVER,
    clock: Clock | None = None,
) -> Container:
    return Container(
        settings=Settings(),
        uow_factory=lambda: FakeUnitOfWork(store),
        read_model=InMemoryReferralReadModel(store),
        trust_gateway=StubTrustGateway(band),
        idempotency_backend=InMemoryIdempotencyBackend(),
        clock=clock or FakeClock(),
    )
