"""/v1/referrals — submit / qualify / convert / get / list (04 §3.7, §4.2).

Verbs only as explicit state-transition sub-resources; camelCase JSON; cursor
pagination with filter[status]; idempotency + problem details are middleware.
"""

from __future__ import annotations

from typing import Annotated

from fastapi import APIRouter, Query, status
from trustos_core.money import Currency, Money

from referral_service.api.http.dependencies import ContainerDep, CurrentActor
from referral_service.api.http.schemas.referrals import (
    ConvertReferralRequest,
    ConvertReferralResponse,
    LinksDto,
    MoneyDto,
    QualifyReferralResponse,
    ReferralDetailResponse,
    ReferralListResponse,
    SchemeSnapshotDto,
    SubmitReferralRequest,
    SubmitReferralResponse,
)
from referral_service.application.commands.convert_referral import ConvertReferral
from referral_service.application.commands.qualify_referral import QualifyReferral
from referral_service.application.commands.submit_referral import SubmitReferral
from referral_service.application.queries.list_referrals import ListReferrals

router = APIRouter(prefix="/v1/referrals", tags=["referrals"])


@router.post("", status_code=status.HTTP_201_CREATED, response_model=SubmitReferralResponse)
async def submit_referral(
    body: SubmitReferralRequest,
    actor: CurrentActor,
    container: ContainerDep,
) -> SubmitReferralResponse:
    result = await container.submit_referral().handle(
        SubmitReferral(
            campaign_id=body.campaign_id,
            prospect_contact_id=body.prospect_contact_id,
            prospect_owner_id=body.prospect_owner_id,
            actor_type=actor.actor_type,
            actor_id=actor.actor_id,
        )
    )
    fixed = None
    if result.scheme_fixed_minor is not None and result.scheme_fixed_currency is not None:
        fixed = MoneyDto(amount_minor=result.scheme_fixed_minor, currency=result.scheme_fixed_currency)
    return SubmitReferralResponse(
        id=result.referral_id,
        status=result.status,
        campaign_id=body.campaign_id,
        scheme_snapshot=SchemeSnapshotDto(
            fixed=fixed,
            rate_basis_points=result.scheme_rate_basis_points,
            min_referrer_band=result.scheme_min_referrer_band,
        ),
        potential_commission=fixed,
        submitted_at=result.submitted_at_iso,  # type: ignore[arg-type]  # pydantic parses RFC 3339
        links=LinksDto.model_validate(
            {
                "self": f"/v1/referrals/{result.referral_id}",
                "campaign": f"/v1/referral-campaigns/{body.campaign_id}",
            }
        ),
    )


@router.post("/{referral_id}/qualify", response_model=QualifyReferralResponse)
async def qualify_referral(
    referral_id: str,
    actor: CurrentActor,
    container: ContainerDep,
) -> QualifyReferralResponse:
    result = await container.qualify_referral().handle(
        QualifyReferral(referral_id=referral_id, actor_type=actor.actor_type, actor_id=actor.actor_id)
    )
    return QualifyReferralResponse(id=result.referral_id, status=result.status)


@router.post("/{referral_id}/convert", response_model=ConvertReferralResponse)
async def convert_referral(
    referral_id: str,
    body: ConvertReferralRequest,
    actor: CurrentActor,
    container: ContainerDep,
) -> ConvertReferralResponse:
    deal_value = None
    if body.deal_value is not None:
        deal_value = Money(body.deal_value.amount_minor, Currency(body.deal_value.currency))
    result = await container.convert_referral().handle(
        ConvertReferral(
            referral_id=referral_id,
            deal_id=body.deal_id,
            deal_value=deal_value,
            actor_type=actor.actor_type,
            actor_id=actor.actor_id,
        )
    )
    return ConvertReferralResponse(
        id=result.referral_id,
        status=result.status,
        commission=MoneyDto(amount_minor=result.commission_minor, currency=result.commission_currency),
    )


@router.get("/{referral_id}", response_model=ReferralDetailResponse)
async def get_referral(referral_id: str, container: ContainerDep) -> ReferralDetailResponse:
    view = await container.get_referral().handle(referral_id)
    return ReferralDetailResponse.from_view(view)


@router.get("", response_model=ReferralListResponse)
async def list_referrals(
    container: ContainerDep,
    status_filter: Annotated[str | None, Query(alias="filter[status]")] = None,
    cursor: Annotated[str | None, Query()] = None,
    limit: Annotated[int, Query(ge=1, le=100)] = 25,
) -> ReferralListResponse:
    statuses = tuple(s for s in status_filter.split(",") if s) if status_filter else None
    page = await container.list_referrals().handle(
        ListReferrals(statuses=statuses, cursor=cursor, limit=limit)
    )
    return ReferralListResponse.from_page(page)
