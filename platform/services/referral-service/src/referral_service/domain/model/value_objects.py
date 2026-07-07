"""Referral-domain value objects (03 §2.1). Money re-exported from trustos-core."""

from __future__ import annotations

from dataclasses import dataclass
from enum import StrEnum

from trustos_core.domain import ValueObject
from trustos_core.money import Currency, Money

__all__ = ["CommissionScheme", "Currency", "Money", "TrustBand"]


class TrustBand(StrEnum):
    """Bands per shared-context §4. Ordered; comparisons use _rank."""

    STARTER = "starter"    # 0-249
    BRONZE = "bronze"      # 250-449
    SILVER = "silver"      # 450-649
    GOLD = "gold"          # 650-849
    PLATINUM = "platinum"  # 850-1000

    @classmethod
    def from_score(cls, dti: int) -> TrustBand:
        if not 0 <= dti <= 1000:
            raise ValueError(f"DTI out of range: {dti}")
        for band, floor in ((cls.PLATINUM, 850), (cls.GOLD, 650), (cls.SILVER, 450), (cls.BRONZE, 250)):
            if dti >= floor:
                return band
        return cls.STARTER

    @property
    def _rank(self) -> int:
        return list(type(self)).index(self)

    def __ge__(self, other: TrustBand) -> bool:  # type: ignore[override]
        return self._rank >= other._rank


@dataclass(frozen=True, slots=True)
class CommissionScheme(ValueObject):
    """How a campaign pays. Exactly one of fixed / rate is set."""

    fixed: Money | None
    rate_basis_points: int | None  # of verified deal value
    min_referrer_band: TrustBand   # anti-gaming: gate high-value campaigns

    def __post_init__(self) -> None:
        if (self.fixed is None) == (self.rate_basis_points is None):
            raise ValueError("exactly one of fixed or rate_basis_points must be set")

    def commission_for(self, deal_value: Money | None) -> Money:
        if self.fixed is not None:
            return self.fixed
        if deal_value is None:
            raise ValueError("rate-based scheme requires a verified deal value")
        assert self.rate_basis_points is not None
        return deal_value.percentage(self.rate_basis_points)
