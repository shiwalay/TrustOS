"""ConvertReferral — linked deal won: commission computed from the scheme snapshot.

Normally driven by the ``deal.deal.won.v1`` consumer; also exposed as the explicit
state-transition sub-resource ``POST /v1/referrals/{id}/convert`` (04 §1.1).
"""

from __future__ import annotations

from dataclasses import dataclass

from trustos_core.clock import Clock, SystemClock
from trustos_core.money import Money

from referral_service.application.errors import ReferralNotFound
from referral_service.application.ports.unit_of_work import UnitOfWork


@dataclass(frozen=True, slots=True)
class ConvertReferral:
    referral_id: str
    deal_id: str                    # "dl_..."
    deal_value: Money | None        # required for rate-based schemes
    actor_type: str
    actor_id: str


@dataclass(frozen=True, slots=True)
class ConvertReferralResult:
    referral_id: str
    status: str
    commission_minor: int
    commission_currency: str


class ConvertReferralHandler:
    def __init__(self, uow: UnitOfWork, clock: Clock | None = None) -> None:
        self._uow = uow
        self._clock = clock or SystemClock()

    async def handle(self, cmd: ConvertReferral) -> ConvertReferralResult:
        async with self._uow as uow:
            referral = await uow.referrals.get_for_update(cmd.referral_id)
            if referral is None:
                raise ReferralNotFound(cmd.referral_id)
            referral.convert(deal_id=cmd.deal_id, deal_value=cmd.deal_value, now=self._clock.now())
            await uow.commit()  # row update + outbox(referral.referral.converted.v1) atomically

        commission = referral.commission
        assert commission is not None  # set by convert()
        return ConvertReferralResult(
            referral_id=referral.id,
            status=referral.status,
            commission_minor=commission.amount_minor,
            commission_currency=commission.currency,
        )
