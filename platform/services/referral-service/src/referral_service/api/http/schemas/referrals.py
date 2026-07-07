"""Pydantic request/response DTOs — camelCase JSON aliases (shared-context §5;
worked example 04 §4.2). Money on the wire: {"amountMinor": ..., "currency": ...}."""

from __future__ import annotations

from datetime import datetime

from pydantic import BaseModel, ConfigDict, Field
from pydantic.alias_generators import to_camel

from referral_service.application.ports.read_model import ReferralView
from referral_service.application.queries.list_referrals import ReferralPage


class CamelModel(BaseModel):
    model_config = ConfigDict(alias_generator=to_camel, populate_by_name=True)


class MoneyDto(CamelModel):
    amount_minor: int = Field(ge=0)
    currency: str = Field(min_length=3, max_length=3)


class SubmitReferralRequest(CamelModel):
    campaign_id: str
    prospect_contact_id: str
    # resolved via contact-service in production; here the client supplies it so the
    # self-referral guard can run. Optional: unknown owner skips only that guard.
    prospect_owner_id: str | None = None


class SchemeSnapshotDto(CamelModel):
    fixed: MoneyDto | None = None
    rate_basis_points: int | None = None
    min_referrer_band: str


class LinksDto(CamelModel):
    self_link: str = Field(alias="self")
    campaign: str


class SubmitReferralResponse(CamelModel):
    id: str
    status: str
    campaign_id: str
    scheme_snapshot: SchemeSnapshotDto
    potential_commission: MoneyDto | None = None
    submitted_at: datetime
    links: LinksDto


class QualifyReferralResponse(CamelModel):
    id: str
    status: str


class ConvertReferralRequest(CamelModel):
    deal_id: str
    deal_value: MoneyDto | None = None  # required for rate-based schemes


class ConvertReferralResponse(CamelModel):
    id: str
    status: str
    commission: MoneyDto


class ReferralDetailResponse(CamelModel):
    id: str
    status: str
    campaign_id: str
    referrer_id: str
    deal_id: str | None
    commission: MoneyDto | None
    submitted_at: datetime
    links: LinksDto

    @classmethod
    def from_view(cls, view: ReferralView) -> ReferralDetailResponse:
        commission = None
        if view.commission_minor is not None and view.commission_currency is not None:
            commission = MoneyDto(amount_minor=view.commission_minor, currency=view.commission_currency)
        return cls(
            id=view.id,
            status=view.status,
            campaign_id=view.campaign_id,
            referrer_id=view.referrer_id,
            deal_id=view.converted_deal_id,
            commission=commission,
            submitted_at=view.submitted_at,
            links=LinksDto.model_validate(
                {
                    "self": f"/v1/referrals/{view.id}",
                    "campaign": f"/v1/referral-campaigns/{view.campaign_id}",
                }
            ),
        )


class PageInfoDto(CamelModel):
    next_cursor: str | None
    has_more: bool


class ReferralListResponse(CamelModel):
    data: list[ReferralDetailResponse]
    page_info: PageInfoDto

    @classmethod
    def from_page(cls, page: ReferralPage) -> ReferralListResponse:
        return cls(
            data=[ReferralDetailResponse.from_view(v) for v in page.items],
            page_info=PageInfoDto(next_cursor=page.next_cursor, has_more=page.has_more),
        )
