"""GetReferral query — reads the referral view, never the write model (03 §2.6)."""

from __future__ import annotations

from referral_service.application.errors import ReferralNotFound
from referral_service.application.ports.read_model import ReferralReadModel, ReferralView


class GetReferralHandler:
    def __init__(self, read_model: ReferralReadModel) -> None:
        self._read_model = read_model

    async def handle(self, referral_id: str) -> ReferralView:
        view = await self._read_model.get(referral_id)
        if view is None:
            raise ReferralNotFound(referral_id)
        return view
