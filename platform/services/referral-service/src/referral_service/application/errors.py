"""ApplicationError hierarchy — mapped to Problem Details at the API edge."""

from __future__ import annotations


class ApplicationError(Exception):
    pass


class CampaignNotFound(ApplicationError):
    def __init__(self, campaign_id: str) -> None:
        super().__init__(f"campaign {campaign_id} not found")
        self.campaign_id = campaign_id


class ReferralNotFound(ApplicationError):
    def __init__(self, referral_id: str) -> None:
        super().__init__(f"referral {referral_id} not found")
        self.referral_id = referral_id


class DuplicateReferral(ApplicationError):
    """409 + existing id in Problem Details (04 §2.1)."""

    def __init__(self, existing_referral_id: str) -> None:
        super().__init__(f"an open referral for this prospect already exists: {existing_referral_id}")
        self.existing_referral_id = existing_referral_id
