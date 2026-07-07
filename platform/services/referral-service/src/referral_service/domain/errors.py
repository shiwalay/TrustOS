"""DomainError hierarchy — invariant violations (03 §1.2 domain/errors.py)."""

from __future__ import annotations


class DomainError(Exception):
    """Base for all referral-domain invariant violations."""


class InvalidReferralTransition(DomainError):
    """State-machine violation (illegal transition or structural guard)."""


class ReferralWindowClosed(DomainError):
    def __init__(self, campaign_id: str) -> None:
        super().__init__(f"campaign {campaign_id} is not open for referrals")
        self.campaign_id = campaign_id


class InsufficientTrustBand(DomainError):
    """Campaign gates referrers below a trust band (anti-gaming, shared-context §4)."""

    def __init__(self, *, required: str, current: str) -> None:
        super().__init__(f"campaign requires trust band >= {required}, referrer is {current}")
        self.required = required
        self.current = current
