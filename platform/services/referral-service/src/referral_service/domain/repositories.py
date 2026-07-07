"""Repository ports — domain owns the interface, infrastructure the impl (03 §2.4)."""

from __future__ import annotations

from typing import Protocol

from referral_service.domain.model.campaign import ReferralCampaign
from referral_service.domain.model.referral import Referral


class ReferralRepository(Protocol):
    async def get(self, referral_id: str) -> Referral | None: ...
    async def get_for_update(self, referral_id: str) -> Referral | None: ...
    async def find_open_by_prospect(
        self, campaign_id: str, prospect_contact_id: str
    ) -> Referral | None: ...
    def add(self, referral: Referral) -> None: ...
    # NB: no save()/update() — UoW flushes tracked aggregates; no delete — referrals are never erased


class CampaignRepository(Protocol):
    async def get(self, campaign_id: str) -> ReferralCampaign | None: ...
