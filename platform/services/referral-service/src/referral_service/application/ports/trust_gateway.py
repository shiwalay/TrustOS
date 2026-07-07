"""TrustGateway port — cross-service read of the referrer's trust band.

Production impl is gRPC to trust-service (TrustService.GetBand, cached 5 min);
called BEFORE the transaction — never hold a DB tx across a network call (03 §2.5).
"""

from __future__ import annotations

from typing import Protocol

from referral_service.domain.model.value_objects import TrustBand


class TrustGateway(Protocol):
    async def get_band(self, user_id: str) -> TrustBand: ...
