"""SqlAlchemyCampaignRepository — read side of the campaign aggregate for the
referral lifecycle (campaign CRUD/publish endpoints are outside this exemplar)."""

from __future__ import annotations

import sqlalchemy as sa
from sqlalchemy.ext.asyncio import AsyncSession

from referral_service.domain.model.campaign import ReferralCampaign
from referral_service.infrastructure.db import tables
from referral_service.infrastructure.db.mapping import campaign_from_row


class SqlAlchemyCampaignRepository:
    def __init__(self, session: AsyncSession) -> None:
        self._session = session

    async def get(self, campaign_id: str) -> ReferralCampaign | None:
        stmt = (
            sa.select(
                tables.campaigns,
                tables.commission_plans.c.plan_type,
                tables.commission_plans.c.config,
                tables.commission_plans.c.currency,
            )
            .join(
                tables.commission_plans,
                tables.campaigns.c.commission_plan_id == tables.commission_plans.c.id,
            )
            .where(tables.campaigns.c.public_id == campaign_id)
        )
        row = (await self._session.execute(stmt)).mappings().one_or_none()
        if row is None:
            return None
        return campaign_from_row(
            row, {"plan_type": row["plan_type"], "config": row["config"], "currency": row["currency"]}
        )
