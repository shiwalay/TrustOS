"""QualifyReferral — org verdict: prospect verified real & in-scope."""

from __future__ import annotations

from dataclasses import dataclass

from trustos_core.clock import Clock, SystemClock

from referral_service.application.errors import ReferralNotFound
from referral_service.application.ports.unit_of_work import UnitOfWork


@dataclass(frozen=True, slots=True)
class QualifyReferral:
    referral_id: str
    actor_type: str  # org member or system rule
    actor_id: str


@dataclass(frozen=True, slots=True)
class QualifyReferralResult:
    referral_id: str
    status: str


class QualifyReferralHandler:
    def __init__(self, uow: UnitOfWork, clock: Clock | None = None) -> None:
        self._uow = uow
        self._clock = clock or SystemClock()

    async def handle(self, cmd: QualifyReferral) -> QualifyReferralResult:
        async with self._uow as uow:
            referral = await uow.referrals.get_for_update(cmd.referral_id)
            if referral is None:
                raise ReferralNotFound(cmd.referral_id)
            referral.qualify(qualified_by=cmd.actor_id, now=self._clock.now())
            await uow.commit()  # row update + outbox(referral.referral.qualified.v1) atomically
        return QualifyReferralResult(referral_id=referral.id, status=referral.status)
