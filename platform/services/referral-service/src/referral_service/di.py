"""Composition root — hand-rolled providers (03 §2.7 pattern; dishka deferred).

The doc's choice is dishka; a single ``Container`` dataclass keeps the same
composition-root discipline (APP-scoped resources built once, REQUEST-scoped
objects from factories, fakes swapped in tests — no monkeypatching) without the
extra dependency while there is exactly one entrypoint.
"""

from __future__ import annotations

from collections.abc import Callable
from dataclasses import dataclass

from sqlalchemy.ext.asyncio import async_sessionmaker, create_async_engine
from trustos_core.clock import Clock, SystemClock
from trustos_core.idempotency import IdempotencyBackend, RedisIdempotencyBackend
from trustos_core.outbox import OutboxWriter

from referral_service.application.commands.convert_referral import ConvertReferralHandler
from referral_service.application.commands.qualify_referral import QualifyReferralHandler
from referral_service.application.commands.submit_referral import SubmitReferralHandler
from referral_service.application.ports.read_model import ReferralReadModel
from referral_service.application.ports.trust_gateway import TrustGateway
from referral_service.application.ports.unit_of_work import UnitOfWork
from referral_service.application.queries.get_referral import GetReferralHandler
from referral_service.application.queries.list_referrals import ListReferralsHandler
from referral_service.domain.model.value_objects import TrustBand
from referral_service.infrastructure.db import tables
from referral_service.infrastructure.db.read_model import SqlAlchemyReferralReadModel
from referral_service.infrastructure.db.unit_of_work import SqlAlchemyUnitOfWork
from referral_service.infrastructure.event_registry import EVENT_REGISTRY
from referral_service.infrastructure.gateways.trust import FixedTrustGateway
from referral_service.settings import Settings


@dataclass(slots=True)
class Container:
    """APP-scoped wiring. Request-scoped objects come from the handler factories."""

    settings: Settings
    uow_factory: Callable[[], UnitOfWork]
    read_model: ReferralReadModel
    trust_gateway: TrustGateway
    idempotency_backend: IdempotencyBackend
    clock: Clock

    # ── request-scoped handler factories ────────────────────────────────────

    def submit_referral(self) -> SubmitReferralHandler:
        return SubmitReferralHandler(self.uow_factory(), self.trust_gateway, self.clock)

    def qualify_referral(self) -> QualifyReferralHandler:
        return QualifyReferralHandler(self.uow_factory(), self.clock)

    def convert_referral(self) -> ConvertReferralHandler:
        return ConvertReferralHandler(self.uow_factory(), self.clock)

    def get_referral(self) -> GetReferralHandler:
        return GetReferralHandler(self.read_model)

    def list_referrals(self) -> ListReferralsHandler:
        return ListReferralsHandler(self.read_model, self.settings.cursor_secret)


def build_container(settings: Settings | None = None) -> Container:
    """Production wiring: Postgres + Redis + outbox. Tests build their own Container
    with in-memory fakes (tests/conftest.py) — same shape, zero infrastructure."""
    settings = settings or Settings()
    engine = create_async_engine(
        settings.database_url, pool_size=settings.db_pool_size, pool_pre_ping=True
    )
    session_factory = async_sessionmaker(engine, expire_on_commit=False)
    outbox = OutboxWriter(
        table=tables.outbox_events,
        registry=EVENT_REGISTRY,
        source=f"//trustos/{settings.service_name}",
    )
    return Container(
        settings=settings,
        uow_factory=lambda: SqlAlchemyUnitOfWork(session_factory, outbox),
        read_model=SqlAlchemyReferralReadModel(session_factory),
        trust_gateway=FixedTrustGateway(TrustBand(settings.trust_band_default)),
        idempotency_backend=RedisIdempotencyBackend(settings.redis_url),
        clock=SystemClock(),
    )
