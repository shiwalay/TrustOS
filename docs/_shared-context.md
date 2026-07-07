# TrustOS — Canonical Architecture Decisions (BINDING)

> Every design document MUST conform to the names, IDs, and decisions in this file.
> If a document needs something not defined here, it must extend — never contradict — this file.

## 1. Platform-Wide Invariants

| Concern | Decision |
|---|---|
| IDs | UUIDv7 everywhere (time-ordered, index-friendly). Public IDs are prefixed: `usr_`, `org_`, `cmt_`, `ref_`, `cmp_`, `dl_`, `evt_` |
| Time | UTC in storage, RFC 3339 on the wire. User TZ stored on profile |
| Money | Integer minor units + ISO 4217 currency code. Never floats. All value movement through `ledger-service` (double-entry) |
| Multi-region | Cell-based architecture. Home-region per user for data residency (GDPR/EU, DPDP/India). Cells: `ap-south-1` (primary launch — India), `us-east-1`, `eu-west-1`. Global control plane; regional data planes |
| Tenancy | Three first-class principals: **User** (person), **Organization** (business), **Community**. Users can act "as" an org (actor model: `actor_type` + `actor_id` on every write) |
| API style | REST (external, OpenAPI 3.1) via gateway; **gRPC** service-to-service; **GraphQL BFF** for mobile aggregate reads (feed, dashboards). API version in path: `/v1/` |
| Events | Kafka. CloudEvents 1.0 envelope, **Protobuf** payloads, Confluent Schema Registry, transactional **outbox pattern + Debezium CDC** for every state change. At-least-once delivery; consumers idempotent via `event_id` dedup |
| Workflows | Temporal for anything multi-step/long-running (KYC, referral settlement, campaign sends, automations, contact import) |
| Search | OpenSearch (marketplace, knowledge, people search) |
| Vector DB | **Qdrant** (self-hosted on k8s; per-collection multitenancy by region) |
| Analytics store | ClickHouse (events, dashboards); Kafka → ClickHouse via materialized pipeline |
| Cache | Redis (Elasticache) — sessions, rate limits, leaderboards (sorted sets), hot profiles, idempotency keys |
| Graph | Neo4j (causal cluster per region) + Neo4j GDS for community detection, collusion detection, path finding |
| AI models | Model-agnostic `ai-gateway`; primary: Anthropic Claude family (claude-sonnet-5 default, claude-haiku-4-5 for cheap/fast classification, claude-fable-5/opus for deep reasoning); image gen pluggable. All AI calls logged, evaluated, cost-attributed |
| Mobile state | Flutter + **Riverpod** (chosen over Bloc: compile-safe DI + state in one model, less boilerplate, better feature-first ergonomics). Offline-first with **Drift** (SQLite) + sync engine |
| AuthN | OIDC. Access JWT (ES256, 15 min) + rotating refresh tokens (30 d, reuse detection), device-bound (DPoP-style). Biometric unlock gates local key usage |
| AuthZ | RBAC (platform + org + community roles) layered with ABAC via **Cerbos** policy engine (policy-as-code, sidecar) |
| Observability | OpenTelemetry (traces/metrics/logs) → Prometheus + Grafana + Tempo + Loki; Sentry for client + server error tracking. Trace context propagated through Kafka headers |
| Edge | Cloudflare: CDN, WAF, bot management, Turnstile, R2 for public media; AWS S3 for private objects |
| CI/CD | GitHub Actions → per-service pipelines → ArgoCD (GitOps) → EKS. Canary via Argo Rollouts |

## 2. Canonical Service Registry

Each service: independently deployable, owns its data (database-per-service), publishes domain events, exposes gRPC internal + (where public) REST via gateway.

| # | Service | Bounded Context | Primary Data Stores |
|---|---|---|---|
| 1 | `api-gateway` | Edge routing, authN enforcement, rate limiting | — (Envoy Gateway + Redis) |
| 2 | `bff-mobile` | GraphQL aggregation for Flutter app | — (reads downstream) |
| 3 | `identity-service` | Auth, sessions, devices, MFA, KYC, business verification (GST/company/domain), social verification | PostgreSQL |
| 4 | `profile-service` | User & org profiles, skills, industries, preferences | PostgreSQL |
| 5 | `contact-service` | Imports (Google/Outlook/phone/CSV/CRM), dedup & merge, enrichment | PostgreSQL |
| 6 | `relationship-service` | Relationship records, interaction timeline, relationship score | PostgreSQL + Neo4j |
| 7 | `trust-service` | Digital Trust Index (0–1000), trust factor ledger, anti-gaming | PostgreSQL + Neo4j |
| 8 | `networking-service` | Match recommendations (meet/collab/partner/hire/mentor/invest), intro orchestration | Neo4j + Qdrant |
| 9 | `referral-service` | Referral campaigns, referral lifecycle, attribution, commission calc | PostgreSQL |
| 10 | `deal-service` | Pipeline: intro → meeting → proposal → closure; invoices; revenue tracking | PostgreSQL |
| 11 | `ledger-service` | Double-entry ledger: commissions, coins, payouts, escrow | PostgreSQL (append-only, event-sourced) |
| 12 | `campaign-service` | Multi-channel campaigns: authoring, personalization, scheduling, analytics | PostgreSQL |
| 13 | `channel-service` | Channel adapters: WhatsApp Cloud API, email (SES), SMS, LinkedIn, Telegram; delivery, webhooks, rate/quality management | PostgreSQL + Redis |
| 14 | `community-service` | Communities, membership, discussions, events, referral boards | PostgreSQL |
| 15 | `marketplace-service` | Listings: services/products/courses/jobs/partnerships; offers, orders | PostgreSQL + OpenSearch |
| 16 | `knowledge-service` | Articles, videos, templates, prompts, SOPs, playbooks; RAG corpus | PostgreSQL + Qdrant |
| 17 | `rewards-service` | XP, coins (via ledger), levels, badges, achievements, streaks | PostgreSQL |
| 18 | `leaderboard-service` | All leaderboards (period × scope), rank computation | Redis (sorted sets) + PostgreSQL snapshots |
| 19 | `automation-service` | User-defined + system automations (birthday, follow-up, drip, journeys) — Temporal workflows | PostgreSQL + Temporal |
| 20 | `ai-gateway` | LLM routing, prompt registry, guardrails, evals, cost metering | PostgreSQL + Redis |
| 21 | `agent-runtime` | The 8 named agents; memory, tools, RAG orchestration | PostgreSQL + Qdrant |
| 22 | `notification-service` | Push (FCM/APNs), in-app inbox, digests, preference center | PostgreSQL + Redis |
| 23 | `analytics-service` | Event ingestion → ClickHouse, dashboard APIs, metric definitions | ClickHouse |
| 24 | `search-service` | Unified search API, indexing consumers | OpenSearch |
| 25 | `media-service` | Upload, virus scan, transcode, CDN URLs | S3/R2 |

## 3. Event Taxonomy (Kafka)

Topic naming: `trustos.<domain>.<aggregate>` — events named `<domain>.<aggregate>.<verb-past-tense>.v<N>`.
Partition key: aggregate ID (e.g. `user_id`) for ordering per aggregate.

Canonical events (non-exhaustive; documents may extend):

- `identity.user.registered.v1`, `identity.user.verified.v1`, `identity.business.verified.v1`, `identity.device.trusted.v1`, `identity.kyc.completed.v1`
- `contact.import.completed.v1`, `contact.contacts.merged.v1`
- `relationship.interaction.recorded.v1`, `relationship.score.updated.v1`, `relationship.connection.established.v1`
- `trust.score.updated.v1`, `trust.factor.recorded.v1`, `trust.anomaly.detected.v1`
- `networking.match.suggested.v1`, `networking.intro.requested.v1`, `networking.intro.accepted.v1`, `networking.meeting.scheduled.v1`
- `referral.campaign.published.v1`, `referral.referral.submitted.v1`, `referral.referral.qualified.v1`, `referral.referral.converted.v1`, `referral.commission.settled.v1`
- `deal.deal.created.v1`, `deal.stage.changed.v1`, `deal.deal.won.v1`, `deal.invoice.issued.v1`, `deal.invoice.paid.v1`
- `ledger.entry.posted.v1`, `ledger.payout.completed.v1`
- `campaign.campaign.scheduled.v1`, `campaign.message.sent.v1`, `campaign.message.delivered.v1`, `campaign.message.read.v1`, `campaign.message.replied.v1`, `campaign.message.failed.v1`
- `community.member.joined.v1`, `community.post.created.v1`, `community.event.created.v1`, `community.event.attended.v1`
- `marketplace.listing.published.v1`, `marketplace.order.placed.v1`, `marketplace.order.completed.v1`
- `knowledge.item.published.v1`, `knowledge.item.consumed.v1`
- `rewards.xp.awarded.v1`, `rewards.badge.unlocked.v1`, `rewards.level.up.v1`
- `automation.run.started.v1`, `automation.run.completed.v1`
- `ai.generation.completed.v1`, `ai.feedback.recorded.v1`

Consumers that update projections (leaderboards, trust, analytics, notifications) subscribe; **no service ever writes to another service's database.**

## 4. Digital Trust Index (DTI) — Canonical Model

`DTI ∈ [0, 1000]`, recomputed event-driven (streaming updates) + nightly full reconciliation.

**DTI = 1000 × Σ wᵢ · sᵢ** where each `sᵢ ∈ [0,1]` and weights:

| Component | Weight | Signal source |
|---|---|---|
| Identity & verification depth | 0.15 | identity-service (KYC tier, GST/domain/social) |
| Referral performance | 0.20 | referral-service (conversion-weighted, Wilson-smoothed) |
| Transaction & deal history | 0.15 | deal-service + ledger (verified revenue, disputes) |
| Relationship quality | 0.15 | relationship-service (reciprocity, depth, diversity — not raw count) |
| Community contribution | 0.10 | community-service (events, helpful posts, moderation signals) |
| Consistency & longevity | 0.10 | tenure, activity regularity (EWMA), promise-keeping (kept meetings/deadlines) |
| Knowledge contribution | 0.05 | knowledge-service (consumed + endorsed content) |
| Peer vouches | 0.05 | trust-service (vouch graph, transitively damped) |
| AI confidence / anomaly | 0.05 | anomaly score inverts: detected manipulation subtracts |

Anti-gaming invariants: time decay (half-life 180 d on behavioral components), small-sample smoothing (Wilson lower bound), graph-based collusion damping (Neo4j GDS: dense reciprocal-vouch clusters get discounted), velocity limits, all raw factors kept in an append-only `trust_factor_ledger` so scores are **explainable and auditable**. Trust bands: Starter 0–249, Bronze 250–449, Silver 450–649, Gold 650–849, Platinum 850–1000.

## 5. Cross-Cutting Standards

- **Idempotency:** all mutating REST endpoints accept `Idempotency-Key`; stored 24 h in Redis.
- **Pagination:** cursor-based (`?cursor=&limit=`), opaque base64 cursors. Never offset for user-facing lists.
- **Rate limits:** token bucket at gateway (per-user, per-org, per-IP tiers) + per-service quotas; headers `RateLimit-*`.
- **Errors:** RFC 9457 Problem Details JSON everywhere.
- **PII:** field-level encryption (AES-256-GCM, envelope via KMS) for phone/email/KYC docs; pseudonymized `user_id` in analytics; right-to-erasure via crypto-shredding of per-user data keys.
- **Feature flags:** OpenFeature + flagd; every risky path flag-gated.
- **Repos:** polyrepo-lite — one `platform` monorepo for backend services (shared proto/contracts, per-service deploy) + `mobile` repo + `infra` repo.
- **Python:** 3.12, FastAPI, SQLAlchemy 2 (async), Pydantic v2, `uv`, ruff, mypy strict. Per-service layout: `api/ → application/ → domain/ → infrastructure/` (Clean Architecture, dependencies point inward).
- **Naming:** snake_case DB & Python, camelCase JSON, PascalCase proto messages.

## 6. Document Conventions

- Diagrams in **Mermaid** (```mermaid blocks) so they render on GitHub.
- Real artifacts, not sketches: SQL DDL, Cypher, YAML manifests, code snippets that would compile/parse.
- Every major decision: state alternatives considered + why rejected (1–3 lines).
- Cross-reference sibling docs by filename (e.g. "see `06-algorithms.md`").
