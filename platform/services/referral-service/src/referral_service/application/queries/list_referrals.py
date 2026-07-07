"""ListReferrals query with cursor pagination (shared-context §5, 04 §1.5).

Cursors are HMAC-signed opaque base64 of the keyset (submitted_at, id) plus a
hash of the active filters — filter drift between pages ⇒ invalid-cursor.
"""

from __future__ import annotations

from dataclasses import dataclass
from datetime import datetime

from trustos_core.pagination import clamp_limit, decode_cursor, encode_cursor

from referral_service.application.ports.read_model import ReferralReadModel, ReferralView


@dataclass(frozen=True, slots=True)
class ListReferrals:
    statuses: tuple[str, ...] | None = None  # filter[status]=a,b
    cursor: str | None = None
    limit: int | None = None


@dataclass(frozen=True, slots=True)
class ReferralPage:
    items: list[ReferralView]
    next_cursor: str | None
    has_more: bool


class ListReferralsHandler:
    def __init__(self, read_model: ReferralReadModel, cursor_secret: str) -> None:
        self._read_model = read_model
        self._secret = cursor_secret

    async def handle(self, query: ListReferrals) -> ReferralPage:
        limit = clamp_limit(query.limit)
        filters = {"status": sorted(query.statuses)} if query.statuses else None

        after: tuple[datetime, str] | None = None
        if query.cursor is not None:
            keys = decode_cursor(query.cursor, secret=self._secret, filters=filters)
            after = (datetime.fromisoformat(str(keys["submittedAt"])), str(keys["id"]))

        rows = await self._read_model.list(statuses=query.statuses, after=after, limit=limit + 1)
        has_more = len(rows) > limit
        items = rows[:limit]

        next_cursor: str | None = None
        if has_more and items:
            last = items[-1]
            next_cursor = encode_cursor(
                {"submittedAt": last.submitted_at.isoformat(), "id": last.id},
                secret=self._secret,
                filters=filters,
            )
        return ReferralPage(items=items, next_cursor=next_cursor, has_more=has_more)
