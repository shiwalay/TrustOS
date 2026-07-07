"""TrustGateway implementations.

The production adapter is gRPC to trust-service (contracts/gen rpc stubs, 5-min
Redis cache, circuit breaker; 03 §7.2). Until trust-service ships, the composition
root wires ``FixedTrustGateway`` — the fail-degraded band from settings, mirroring
the documented fallback ("caller's cached band, else STARTER").
"""

from __future__ import annotations

from referral_service.domain.model.value_objects import TrustBand


class FixedTrustGateway:
    def __init__(self, band: TrustBand = TrustBand.STARTER) -> None:
        self._band = band

    async def get_band(self, user_id: str) -> TrustBand:
        return self._band
