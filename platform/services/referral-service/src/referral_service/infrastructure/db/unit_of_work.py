"""SqlAlchemyUnitOfWork + transactional outbox (03 §2.4).

Aggregate rows and outbox rows commit in ONE Postgres transaction; Debezium
tails the WAL and publishes to Kafka. No dual-write, no lost events.
"""

from __future__ import annotations

from types import TracebackType

from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from trustos_core.outbox import OutboxWriter

from referral_service.infrastructure.db.campaign_repository import SqlAlchemyCampaignRepository
from referral_service.infrastructure.db.referral_repository import SqlAlchemyReferralRepository


class SqlAlchemyUnitOfWork:
    """Implements application.ports.unit_of_work.UnitOfWork.

    Contract: exactly-once state+events atomically, or nothing.
      async with uow:
          ... mutate aggregates via uow.referrals ...
          await uow.commit()
    """

    def __init__(self, session_factory: async_sessionmaker[AsyncSession], outbox: OutboxWriter) -> None:
        self._session_factory = session_factory
        self._outbox = outbox

    async def __aenter__(self) -> SqlAlchemyUnitOfWork:
        self._session = self._session_factory()
        self.referrals = SqlAlchemyReferralRepository(self._session)
        self.campaigns = SqlAlchemyCampaignRepository(self._session)
        return self

    async def commit(self) -> None:
        await self.referrals.flush()
        events = [
            event
            for aggregate, _ in self.referrals.seen.values()
            for event in aggregate.collect_events()
        ]
        if events:
            # INSERT INTO outbox_events (id, aggregate_type, aggregate_id, event_type, payload, headers)
            await self._outbox.write(self._session, events)
        await self._session.commit()

    async def rollback(self) -> None:
        await self._session.rollback()

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        tb: TracebackType | None,
    ) -> None:
        try:
            if exc_type is not None:
                await self.rollback()
        finally:
            await self._session.close()
