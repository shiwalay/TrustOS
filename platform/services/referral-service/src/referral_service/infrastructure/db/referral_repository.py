"""SqlAlchemyReferralRepository (03 §2.4): implements the domain ReferralRepository
port; tracks loaded/added aggregates for the UoW; optimistic locking via version."""

from __future__ import annotations

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from referral_service.domain.model.referral import Referral
from referral_service.infrastructure.db import tables
from referral_service.infrastructure.db.mapping import (
    prospect_identity_hash,
    referral_from_row,
    referral_to_row,
    to_uuid,
)


class StaleAggregateError(Exception):
    """Concurrent write lost the optimistic-lock race; handlers retry the command."""

    def __init__(self, referral_id: str) -> None:
        super().__init__(f"referral {referral_id} was modified concurrently")
        self.referral_id = referral_id


class SqlAlchemyReferralRepository:
    """Tracks loaded/added aggregates in ``seen``; the UoW calls ``flush()`` inside
    the transaction."""

    def __init__(self, session: AsyncSession) -> None:
        self._session = session
        self.seen: dict[str, tuple[Referral, int]] = {}  # id -> (aggregate, loaded_version)

    async def get(self, referral_id: str) -> Referral | None:
        return await self._load(
            sa.select(tables.referrals).where(tables.referrals.c.public_id == referral_id)
        )

    async def get_for_update(self, referral_id: str) -> Referral | None:
        stmt = (
            sa.select(tables.referrals)
            .where(tables.referrals.c.public_id == referral_id)
            .with_for_update()
        )
        return await self._load(stmt)

    async def find_open_by_prospect(
        self, campaign_id: str, prospect_contact_id: str
    ) -> Referral | None:
        stmt = sa.select(tables.referrals).where(
            tables.referrals.c.campaign_id == to_uuid(campaign_id),
            tables.referrals.c.prospect_identity_hash == prospect_identity_hash(prospect_contact_id),
            tables.referrals.c.state.notin_(("rejected", "expired")),
        )
        return await self._load(stmt)

    def add(self, referral: Referral) -> None:
        self.seen[referral.id] = (referral, -1)  # -1 => INSERT on flush

    async def flush(self) -> None:
        """Called by the UoW inside the transaction. Optimistic concurrency via version."""
        for referral, loaded_version in self.seen.values():
            row = referral_to_row(referral)
            if loaded_version == -1:
                row["version"] = 0
                await self._session.execute(sa.insert(tables.referrals).values(**row))
                referral.version = 0
            else:
                row["version"] = loaded_version + 1
                result = await self._session.execute(
                    sa.update(tables.referrals)
                    .where(
                        tables.referrals.c.public_id == referral.id,
                        tables.referrals.c.version == loaded_version,
                    )
                    .values(**row)
                )
                if result.rowcount != 1:
                    raise StaleAggregateError(referral.id)
                referral.version = loaded_version + 1

    async def _load(self, stmt: sa.Select[tuple]) -> Referral | None:  # type: ignore[type-arg]
        row = (await self._session.execute(stmt)).mappings().one_or_none()
        if row is None:
            return None
        referral = referral_from_row(row)
        self.seen[referral.id] = (referral, row["version"])
        return referral
