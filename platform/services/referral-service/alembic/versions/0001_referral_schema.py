"""Initial referral schema.

DDL per 05-data-architecture.md: §2.1 (uuid_generate_v7), §2.2 (updated_at
trigger), §2.3 (outbox_events), §3.5 (commission_plans, campaigns, referrals)
plus the consumer-dedup processed_events table (03 §4.2).

Additive columns on referrals beyond the §3.5 DDL, required by the aggregate
design in 03-backend-architecture.md:
- scheme_snapshot jsonb  — commission scheme captured AT SUBMISSION (03 §2.2)
- org_id uuid            — denormalized campaign owner (05 §1.2: denormalize freely)
- version integer        — optimistic concurrency (03 §2.4)

Revision ID: 0001
Revises:
Create Date: 2026-07-07
"""

from __future__ import annotations

from alembic import op

revision = "0001"
down_revision = None
branch_labels = None
depends_on = None


def upgrade() -> None:
    # ── §2.1 UUIDv7 generator (PostgreSQL 16 has no native one) ─────────────
    op.execute("CREATE EXTENSION IF NOT EXISTS pgcrypto;")
    op.execute(
        """
        -- RFC 9562 UUIDv7: 48-bit unix-millis + version/variant bits over random tail
        CREATE OR REPLACE FUNCTION uuid_generate_v7()
        RETURNS uuid
        LANGUAGE sql VOLATILE PARALLEL SAFE
        AS $$
          SELECT encode(
            set_bit(
              set_bit(
                overlay(uuid_send(gen_random_uuid())
                        PLACING substring(int8send((extract(epoch FROM clock_timestamp()) * 1000)::bigint) FROM 3)
                        FROM 1 FOR 6),
                52, 1),
              53, 1),
            'hex')::uuid;
        $$;
        """
    )

    # ── §2.2 updated_at trigger function (installed once per database) ──────
    op.execute(
        """
        CREATE OR REPLACE FUNCTION touch_updated_at()
        RETURNS trigger LANGUAGE plpgsql AS $$
        BEGIN
          NEW.updated_at := now();
          RETURN NEW;
        END $$;
        """
    )

    # ── §3.5 commission_plans ────────────────────────────────────────────────
    op.execute(
        """
        CREATE TABLE commission_plans (
            id             uuid        PRIMARY KEY DEFAULT uuid_generate_v7(),
            org_id         uuid        NOT NULL,                   -- opaque (profile-service org)
            name           text        NOT NULL,
            plan_type      text        NOT NULL CHECK (plan_type IN ('flat','percent','tiered','hybrid')),
            config         jsonb       NOT NULL,                   -- {'percent': 10} / tier ladders
            currency       char(3)     NOT NULL,
            cap_minor      bigint      CHECK (cap_minor IS NULL OR cap_minor > 0),
            active         boolean     NOT NULL DEFAULT true,
            created_at     timestamptz NOT NULL DEFAULT now(),
            updated_at     timestamptz NOT NULL DEFAULT now()
        );
        """
    )
    op.execute("CREATE INDEX commission_plans_org_idx ON commission_plans (org_id) WHERE active;")
    op.execute(
        "CREATE TRIGGER commission_plans_touch BEFORE UPDATE ON commission_plans "
        "FOR EACH ROW EXECUTE FUNCTION touch_updated_at();"
    )

    # ── §3.5 campaigns (public_id prefix 'cmp_') ─────────────────────────────
    op.execute(
        """
        CREATE TABLE campaigns (
            id                 uuid        PRIMARY KEY DEFAULT uuid_generate_v7(),
            public_id          text        NOT NULL UNIQUE,        -- 'cmp_…'
            org_id             uuid        NOT NULL,               -- opaque
            commission_plan_id uuid        NOT NULL REFERENCES commission_plans (id),
            title              text        NOT NULL,
            description        text,
            target_criteria    jsonb       NOT NULL DEFAULT '{}'::jsonb,  -- ideal prospect profile
            status             text        NOT NULL DEFAULT 'draft'
                               CHECK (status IN ('draft','published','paused','ended','archived')),
            min_referrer_band  text        CHECK (min_referrer_band IN ('starter','bronze','silver','gold','platinum')
                                                  OR min_referrer_band IS NULL),
            budget_minor       bigint      CHECK (budget_minor IS NULL OR budget_minor > 0),
            budget_currency    char(3),
            starts_at          timestamptz,
            ends_at            timestamptz,
            published_at       timestamptz,
            created_at         timestamptz NOT NULL DEFAULT now(),
            updated_at         timestamptz NOT NULL DEFAULT now(),
            CHECK (ends_at IS NULL OR starts_at IS NULL OR ends_at > starts_at),
            CHECK ((budget_minor IS NULL) = (budget_currency IS NULL)),
            CHECK (status <> 'published' OR published_at IS NOT NULL)
        );
        """
    )
    op.execute("CREATE INDEX campaigns_org_idx    ON campaigns (org_id, status);")
    op.execute("CREATE INDEX campaigns_live_idx   ON campaigns (status, ends_at) WHERE status = 'published';")
    op.execute(
        "CREATE TRIGGER campaigns_touch BEFORE UPDATE ON campaigns "
        "FOR EACH ROW EXECUTE FUNCTION touch_updated_at();"
    )

    # ── §3.5 referrals (public_id prefix 'ref_') ─────────────────────────────
    op.execute(
        """
        CREATE TABLE referrals (
            id                    uuid        PRIMARY KEY DEFAULT uuid_generate_v7(),
            public_id             text        NOT NULL UNIQUE,      -- 'ref_…'
            campaign_id           uuid        NOT NULL REFERENCES campaigns (id),
            org_id                uuid        NOT NULL,             -- denormalized campaign owner
            referrer_user_id      uuid        NOT NULL,             -- opaque
            prospect_contact_id   uuid,                             -- opaque contact-service ID
            prospect_name_enc     bytea,                            -- for non-contact prospects
            prospect_identity_hash bytea      NOT NULL,             -- blind index of prospect email/phone
            referrer_trust_snapshot smallint  CHECK (referrer_trust_snapshot BETWEEN 0 AND 1000),
            scheme_snapshot       jsonb       NOT NULL,             -- commission scheme AT SUBMISSION
            state                 text        NOT NULL DEFAULT 'submitted'
                                  CHECK (state IN ('submitted','qualified','contacted',
                                                   'converted','settled','rejected','expired')),
            deal_id               uuid,                             -- opaque deal-service ID once converted
            converted_value_minor bigint      CHECK (converted_value_minor IS NULL OR converted_value_minor >= 0),
            converted_currency    char(3),
            commission_minor      bigint      CHECK (commission_minor IS NULL OR commission_minor >= 0),
            commission_currency   char(3),
            ledger_journal_id     uuid,                             -- opaque ledger-service journal entry
            version               integer     NOT NULL DEFAULT 0,   -- optimistic concurrency
            submitted_at          timestamptz NOT NULL DEFAULT now(),
            qualified_at          timestamptz,
            converted_at          timestamptz,
            settled_at            timestamptz,
            closed_reason         text,
            created_at            timestamptz NOT NULL DEFAULT now(),
            updated_at            timestamptz NOT NULL DEFAULT now(),
            CHECK (state <> 'converted' OR converted_at IS NOT NULL),
            CHECK (state <> 'settled'   OR settled_at IS NOT NULL),
            CHECK ((converted_value_minor IS NULL) = (converted_currency IS NULL)),
            -- one submission per (campaign, referrer, prospect): kills dup-spam at the constraint level
            UNIQUE (campaign_id, referrer_user_id, prospect_identity_hash)
        );
        """
    )
    op.execute(
        "CREATE INDEX referrals_campaign_state_idx ON referrals (campaign_id, state, submitted_at DESC);"
    )
    op.execute(
        "CREATE INDEX referrals_referrer_idx       ON referrals (referrer_user_id, submitted_at DESC);"
    )
    op.execute(
        "CREATE INDEX referrals_settlement_idx     ON referrals (state, converted_at) "
        "WHERE state = 'converted';"
    )
    op.execute("CREATE INDEX referrals_prospect_idx       ON referrals (prospect_identity_hash);")
    op.execute(
        "CREATE TRIGGER referrals_touch BEFORE UPDATE ON referrals "
        "FOR EACH ROW EXECUTE FUNCTION touch_updated_at();"
    )

    # ── §2.3 transactional outbox (identical in every service database) ─────
    op.execute(
        """
        CREATE TABLE outbox_events (
            id             uuid        PRIMARY KEY DEFAULT uuid_generate_v7(),
            aggregate_type text        NOT NULL,           -- 'referral', ...
            aggregate_id   uuid        NOT NULL,           -- Kafka partition key
            event_type     text        NOT NULL,           -- 'referral.referral.submitted.v1'
            payload        bytea       NOT NULL,
            headers        jsonb       NOT NULL DEFAULT '{}'::jsonb,  -- traceparent, actor
            created_at     timestamptz NOT NULL DEFAULT now()
        );
        """
    )
    op.execute("CREATE INDEX outbox_events_created_at_idx ON outbox_events (created_at);")

    # ── consumer-side dedup (03 §4.2 idempotent consumer) ────────────────────
    op.execute(
        """
        CREATE TABLE processed_events (
            event_id       uuid        NOT NULL,
            consumer_group text        NOT NULL,
            processed_at   timestamptz NOT NULL DEFAULT now(),
            PRIMARY KEY (event_id, consumer_group)
        );
        """
    )


def downgrade() -> None:
    op.execute("DROP TABLE IF EXISTS processed_events;")
    op.execute("DROP TABLE IF EXISTS outbox_events;")
    op.execute("DROP TABLE IF EXISTS referrals;")
    op.execute("DROP TABLE IF EXISTS campaigns;")
    op.execute("DROP TABLE IF EXISTS commission_plans;")
    op.execute("DROP FUNCTION IF EXISTS touch_updated_at();")
    op.execute("DROP FUNCTION IF EXISTS uuid_generate_v7();")
