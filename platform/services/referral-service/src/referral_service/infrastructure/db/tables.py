"""SQLAlchemy Core Table objects — imperative mapping (03 §2.4), matching the
referral DDL in 05-data-architecture.md §3.5 (see alembic/versions/0001).

Not declarative ORM: aggregates stay plain dataclasses with no metaclass magic
and no lazy-loading surprises.
"""

from __future__ import annotations

import sqlalchemy as sa
from sqlalchemy.dialects.postgresql import BYTEA, JSONB
from sqlalchemy.dialects.postgresql import UUID as PG_UUID
from trustos_core.outbox import make_outbox_table, make_processed_events_table

metadata = sa.MetaData()

_uuid = PG_UUID(as_uuid=True).with_variant(sa.Uuid(), "sqlite")
_jsonb = JSONB().with_variant(sa.JSON(), "sqlite")
_bytea = BYTEA().with_variant(sa.LargeBinary(), "sqlite")

commission_plans = sa.Table(
    "commission_plans",
    metadata,
    sa.Column("id", _uuid, primary_key=True),
    sa.Column("org_id", _uuid, nullable=False),  # opaque (profile-service org)
    sa.Column("name", sa.Text, nullable=False),
    sa.Column("plan_type", sa.Text, nullable=False),  # flat|percent|tiered|hybrid (CHECK in DDL)
    sa.Column("config", _jsonb, nullable=False),      # {'percent': 10} / tier ladders
    sa.Column("currency", sa.CHAR(3), nullable=False),
    sa.Column("cap_minor", sa.BigInteger),
    sa.Column("active", sa.Boolean, nullable=False, server_default=sa.text("true")),
    sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
    sa.Column("updated_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
)

campaigns = sa.Table(
    "campaigns",
    metadata,
    sa.Column("id", _uuid, primary_key=True),
    sa.Column("public_id", sa.Text, nullable=False, unique=True),  # 'cmp_…'
    sa.Column("org_id", _uuid, nullable=False),  # opaque
    sa.Column("commission_plan_id", _uuid, sa.ForeignKey("commission_plans.id"), nullable=False),
    sa.Column("title", sa.Text, nullable=False),
    sa.Column("description", sa.Text),
    sa.Column("target_criteria", _jsonb, nullable=False, server_default=sa.text("'{}'")),
    sa.Column("status", sa.Text, nullable=False, server_default="draft"),
    sa.Column("min_referrer_band", sa.Text),
    sa.Column("budget_minor", sa.BigInteger),
    sa.Column("budget_currency", sa.CHAR(3)),
    sa.Column("starts_at", sa.TIMESTAMP(timezone=True)),
    sa.Column("ends_at", sa.TIMESTAMP(timezone=True)),
    sa.Column("published_at", sa.TIMESTAMP(timezone=True)),
    sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
    sa.Column("updated_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
)

referrals = sa.Table(
    "referrals",
    metadata,
    sa.Column("id", _uuid, primary_key=True),
    sa.Column("public_id", sa.Text, nullable=False, unique=True),  # 'ref_…'
    sa.Column("campaign_id", _uuid, sa.ForeignKey("campaigns.id"), nullable=False),
    sa.Column("org_id", _uuid, nullable=False),  # denormalized campaign owner (05 §1.2)
    sa.Column("referrer_user_id", _uuid, nullable=False),  # opaque
    sa.Column("prospect_contact_id", _uuid),               # opaque contact-service ID
    sa.Column("prospect_name_enc", _bytea),                # for non-contact prospects
    sa.Column("prospect_identity_hash", _bytea, nullable=False),  # blind index
    sa.Column("referrer_trust_snapshot", sa.SmallInteger),
    sa.Column("scheme_snapshot", _jsonb, nullable=False),  # commission scheme AT SUBMISSION (03 §2.2)
    sa.Column("state", sa.Text, nullable=False, server_default="submitted"),
    sa.Column("deal_id", _uuid),  # opaque deal-service ID once converted
    sa.Column("converted_value_minor", sa.BigInteger),
    sa.Column("converted_currency", sa.CHAR(3)),
    sa.Column("commission_minor", sa.BigInteger),
    sa.Column("commission_currency", sa.CHAR(3)),
    sa.Column("ledger_journal_id", _uuid),  # opaque ledger-service journal entry
    sa.Column("version", sa.Integer, nullable=False, server_default="0"),  # optimistic lock (03 §2.4)
    sa.Column("submitted_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
    sa.Column("qualified_at", sa.TIMESTAMP(timezone=True)),
    sa.Column("converted_at", sa.TIMESTAMP(timezone=True)),
    sa.Column("settled_at", sa.TIMESTAMP(timezone=True)),
    sa.Column("closed_reason", sa.Text),
    sa.Column("created_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
    sa.Column("updated_at", sa.TIMESTAMP(timezone=True), nullable=False, server_default=sa.func.now()),
    # one submission per (campaign, referrer, prospect): kills dup-spam at the constraint level
    sa.UniqueConstraint(
        "campaign_id", "referrer_user_id", "prospect_identity_hash",
        name="referrals_campaign_id_referrer_user_id_prospect_identity_hash_key",
    ),
)

outbox_events = make_outbox_table(metadata)
processed_events = make_processed_events_table(metadata)
