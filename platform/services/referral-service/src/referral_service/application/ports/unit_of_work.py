"""UnitOfWork port (03 §2.4). Contract: state + events atomically, or nothing.

    async with uow:
        ... mutate aggregates via uow.referrals / read uow.campaigns ...
        await uow.commit()   # flush + drain aggregate events into the outbox + COMMIT
"""

from __future__ import annotations

from types import TracebackType
from typing import Protocol

from referral_service.domain.repositories import CampaignRepository, ReferralRepository


class UnitOfWork(Protocol):
    referrals: ReferralRepository
    campaigns: CampaignRepository

    async def __aenter__(self) -> UnitOfWork: ...

    async def __aexit__(
        self,
        exc_type: type[BaseException] | None,
        exc: BaseException | None,
        tb: TracebackType | None,
    ) -> None: ...

    async def commit(self) -> None: ...

    async def rollback(self) -> None: ...
