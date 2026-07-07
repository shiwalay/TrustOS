"""ReferralCampaign aggregate root — the minimal shape the referral lifecycle needs
(publish/close lifecycle endpoints live outside this exemplar's scope)."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from enum import StrEnum

from trustos_core.domain import AggregateRoot

from referral_service.domain.model.value_objects import CommissionScheme


class CampaignStatus(StrEnum):
    DRAFT = "draft"
    PUBLISHED = "published"
    PAUSED = "paused"
    ENDED = "ended"
    ARCHIVED = "archived"


@dataclass(kw_only=True, eq=False)
class ReferralCampaign(AggregateRoot):
    """Campaign aggregate (public_id prefix 'cmp_'). Referrals snapshot its scheme
    at submission — later scheme changes never reprice open referrals."""

    org_id: str  # "org_..."
    title: str
    scheme: CommissionScheme
    status: CampaignStatus
    starts_at: datetime | None = None
    ends_at: datetime | None = None

    def is_open(self, *, now: datetime) -> bool:
        if self.status is not CampaignStatus.PUBLISHED:
            return False
        if self.starts_at is not None and now < self.starts_at:
            return False
        return not (self.ends_at is not None and now >= self.ends_at)
