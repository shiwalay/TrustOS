"""SQL read model for referral queries (CQRS read side, 03 §2.6).

Reads the referrals table directly with keyset pagination; when read volume
justifies it this moves to a projection table fed by the service's own events.
"""

from __future__ import annotations

from collections.abc import Mapping
from datetime import datetime
from typing import Any

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession, async_sessionmaker
from trustos_core.ids import public_id

from referral_service.application.ports.read_model import ReferralView
from referral_service.infrastructure.db import tables
from referral_service.infrastructure.db.mapping import (
    PREFIX_CAMPAIGN,
    PREFIX_DEAL,
    PREFIX_USER,
    to_uuid,
)

_COLUMNS = (
    tables.referrals.c.public_id,
    tables.referrals.c.campaign_id,
    tables.referrals.c.referrer_user_id,
    tables.referrals.c.state,
    tables.referrals.c.submitted_at,
    tables.referrals.c.deal_id,
    tables.referrals.c.commission_minor,
    tables.referrals.c.commission_currency,
)


def _view(row: Mapping[str, Any]) -> ReferralView:
    return ReferralView(
        id=row["public_id"],
        campaign_id=public_id(PREFIX_CAMPAIGN, row["campaign_id"]),
        referrer_id=public_id(PREFIX_USER, row["referrer_user_id"]),
        status=row["state"],
        submitted_at=row["submitted_at"],
        converted_deal_id=public_id(PREFIX_DEAL, row["deal_id"]) if row["deal_id"] else None,
        commission_minor=row["commission_minor"],
        commission_currency=row["commission_currency"],
    )


class SqlAlchemyReferralReadModel:
    def __init__(self, session_factory: async_sessionmaker[AsyncSession]) -> None:
        self._session_factory = session_factory

    async def get(self, referral_id: str) -> ReferralView | None:
        stmt = sa.select(*_COLUMNS).where(tables.referrals.c.public_id == referral_id)
        async with self._session_factory() as session:
            row = (await session.execute(stmt)).mappings().one_or_none()
        return _view(row) if row else None

    async def list(
        self,
        *,
        statuses: tuple[str, ...] | None,
        after: tuple[datetime, str] | None,
        limit: int,
    ) -> list[ReferralView]:
        stmt = (
            sa.select(*_COLUMNS)
            .order_by(tables.referrals.c.submitted_at.desc(), tables.referrals.c.id.desc())
            .limit(limit)
        )
        if statuses:
            stmt = stmt.where(tables.referrals.c.state.in_(statuses))
        if after is not None:
            after_at, after_id = after
            stmt = stmt.where(
                sa.tuple_(tables.referrals.c.submitted_at, tables.referrals.c.id)
                < sa.tuple_(sa.literal(after_at), sa.literal(to_uuid(after_id)))
            )
        async with self._session_factory() as session:
            rows = (await session.execute(stmt)).mappings().all()
        return [_view(row) for row in rows]
