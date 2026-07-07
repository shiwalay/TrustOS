"""Read-model port (CQRS read side, 03 §2.6). Queries never touch aggregates or
the UoW — they read a denormalized view, keyset-ordered for cursor pagination."""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime
from typing import Protocol


@dataclass(frozen=True, slots=True)
class ReferralView:
    """Denormalized row for reads. Money kept as raw minor units + code — the API
    layer shapes the JSON."""

    id: str                    # "ref_..."
    campaign_id: str           # "cmp_..."
    referrer_id: str           # "usr_..."
    status: str
    submitted_at: datetime
    converted_deal_id: str | None
    commission_minor: int | None
    commission_currency: str | None


class ReferralReadModel(Protocol):
    async def get(self, referral_id: str) -> ReferralView | None: ...

    async def list(
        self,
        *,
        statuses: tuple[str, ...] | None,
        after: tuple[datetime, str] | None,
        limit: int,
    ) -> list[ReferralView]:
        """Newest first (submitted_at DESC, id DESC). ``after`` is the keyset of the
        previous page's last row; implementations return up to ``limit`` rows."""
        ...
