# 14 — Future Roadmap (36 Months)

> Conforms to `_shared-context.md` (BINDING). Extends `_brief.md` vision.
> Sibling refs: `11-security-architecture.md` (DPIA, fraud, compliance), `12-devops-platform.md` (scaling ladder,
> cost, cells), `13-testing-performance.md` (quality gates). Scale milestones here map 1:1 to `12 §6`.

**Sequencing thesis — the BNI wedge.** TrustOS could boil the ocean (15 modules, `_brief`). Instead we win one
painful, high-trust, high-frequency workflow first — **structured business referrals inside tight professional
communities** (the "BNI wedge": weekly referral groups, masterminds, chambers of commerce). That user already tracks
referrals in spreadsheets and WhatsApp; they have money on the line and meet weekly, so retention and word-of-mouth
are structural. From that beachhead we layer relationship intelligence → trust graph → marketplace → AI copilot →
platform. Each phase must *stand on its own* (usable, monetizable) before the next.

**Phase overview**

| Phase | Months | Theme | Users (end) | Cells / regions (`12 §6`) | Eng |
|---|---|---|---|---|---|
| 0 | 0–6 | Foundation: identity + contacts + relationships + trust v1 | 50k | 1 cell, `ap-south-1` | 15 → 30 |
| 1 | 6–12 | Referral + communities (BNI wedge) | 500k | 1 cell | 30 → 55 |
| 2 | 12–20 | Campaigns + marketplace + AI copilot GA | 5M | 1 cell + read-scale | 55 → 90 |
| 3 | 20–30 | Multi-region + enterprise + API/developer platform | 25M | multi-cell, +`eu`/`us` | 90 → 130 |
| 4 | 30–36 | Network-effect moats: portable trust, TrustOS-as-infra | 100M | many cells | 130 → 150 |

---

## Phase 0 — Foundation (Months 0–6)

**Goals.** Prove the core loop: a professional imports their network, sees a clean relationship graph, and gets a
first, *explainable* Trust score. One country (India), 10 cities. Nail data quality and the trust primitive before
anything is built on top of it.

**Modules shipped**
- `identity-service`: OIDC, WebAuthn/passkey, device binding, phone/email verification, business verification v1 (GST/domain) — auth per `11 §2`.
- `profile-service`: user & org profiles.
- `contact-service`: Google/phone/CSV import, dedup & merge (the hardest data problem — get it right early).
- `relationship-service`: relationship records, interaction timeline, relationship score v1; Neo4j graph.
- `trust-service`: **DTI v1** (`_shared-context §4`) — identity + relationship + consistency components only (referral/deal weights dark until Phase 1 data exists), append-only `trust_factor_ledger`, explainability UI.
- Platform spine: `api-gateway`, `bff-mobile`, Kafka+outbox/CDC, Temporal, Cerbos, OTel stack, single-cell EKS (`12 §1`).
- Flutter app (offline-first, Drift) — `09-mobile-architecture.md`.

**Scale targets.** 50k users, 10 cities; single cell handles it trivially (`12 §6`, 0→1M row). p99 SLOs met (`12 §4.3`).

**Team topology (15 → 30 eng)**
| Squad | Owns |
|---|---|
| Identity & Trust | identity, profile, trust, DTI |
| Relationship & Data | contact, relationship, Neo4j, dedup/merge |
| Mobile | Flutter app, sync engine |
| Platform | EKS, CI/CD, observability, Cerbos, Kafka |
| (forming) Security | threat model, fraud primitives (`11`) |

**Key risks.** (1) Contact dedup/merge quality — bad merges destroy trust in the product; (2) DTI feels arbitrary if
not explainable; (3) cold-start (empty graph). **Mitigations:** heavy investment in dedup ML + human-review UX; DTI
explainability from day 1; import-first onboarding so the graph is never empty.

**Exit criteria.** ≥ 40% of new users complete import + see a graph; DTI explainability rated clear by ≥ 70% surveyed;
dedup false-merge rate < 0.5%; single-cell SLOs green under 50k.

---

## Phase 1 — Referral + Communities: the BNI wedge (Months 6–12)

**Goals.** Monetize and retain via structured referrals inside communities. This is the wedge — make TrustOS the
system of record for a referral group's weekly business, replacing spreadsheets/WhatsApp.

**Modules shipped**
- `referral-service`: campaigns, referral lifecycle, attribution, commission calc.
- `deal-service`: intro → meeting → proposal → closure pipeline, revenue tracking.
- `ledger-service`: double-entry ledger (commissions, coins, escrow) — money path with `11 §9.2` fraud rules.
- `community-service`: masterminds/referral groups, membership, discussions, events, referral boards, community trust ranking.
- `rewards-service` + `leaderboard-service`: XP/coins/badges, community & city leaderboards (Redis sorted sets).
- `automation-service` v1 (Temporal): referral reminders, meeting reminders, follow-ups.
- DTI now uses **referral performance + deal history** weights (real data exists) — anti-gaming online (`11 §9.1`, `06-algorithms.md`).

**Scale targets.** 500k users; still 1 cell but read-replicas + pgbouncer + dedicated leaderboard Redis emerging (`12 §6`, 1M row triggers).

**Team topology (30 → 55)**
| New/grown squad | Owns |
|---|---|
| Referral & Deals | referral, deal, attribution |
| Money & Ledger | ledger, escrow, payout, PSP integration (SAQ-A, `11 §8.3`) |
| Community | community, events, referral boards |
| Growth/Rewards | rewards, leaderboard, gamification |
| Fraud & Integrity | trust-manipulation red team, money-fraud rules (`11 §9`) |

**Key risks.** (1) Referral fraud/collusion the moment money appears; (2) trust manipulation via vouch rings; (3)
community land-grab (empty communities die). **Mitigations:** fraud squad stood up *before* payouts; escrow +
KYC-tier gating on payout; collusion damping (Neo4j GDS); seed communities with anchor groups (real BNI-style chapters).

**Exit criteria.** ≥ 5 active referral communities per launch city with weekly referral volume; verified referral→deal
conversion tracked end-to-end; fraud loss < 1% of commission GMV; DTI manipulation red-team can't move a score > X
without detection; positive contribution margin on referral take-rate.

---

## Phase 2 — Campaigns + Marketplace + AI Copilot GA (Months 12–20)

**Goals.** Turn the network into a growth + commerce engine. AI becomes a headline feature, not a helper. Broaden
from referrals to full business networking.

**Modules shipped**
- `campaign-service` + `channel-service`: multi-channel (WhatsApp Cloud API first, then email/SMS/Telegram/LinkedIn), AI-generated messages/images, scheduling, analytics — quality-tier governance (`11 §1` Surface 5).
- `marketplace-service`: services/products/courses/jobs/partnerships; offers, orders; OpenSearch.
- `knowledge-service`: articles/templates/prompts/SOPs; RAG corpus (Qdrant).
- `networking-service`: AI match recommendations (meet/collab/partner/hire/mentor/invest); intro orchestration.
- `ai-gateway` + `agent-runtime` **GA**: the 8 agents (`_brief`) with memory, tools, RAG, guardrails, evals — hardened per `11 §7.4`, gated per `13 §3`.
- `analytics-service`: ClickHouse dashboards (business/relationship/trust/referral/revenue/campaign/community).
- DTI full model (all 9 components, `_shared-context §4`).

**Scale targets.** 5M users; Postgres partitioning of hot tables, KEDA consumer autoscale, CDN feed caching (`12 §6`, 1M→10M).

**Team topology (55 → 90)**
| New/grown squad | Owns |
|---|---|
| Campaigns & Channels | campaign, channel, WhatsApp/quality |
| Marketplace | listings, orders, search |
| Knowledge & RAG | knowledge, Qdrant corpus |
| AI Platform | ai-gateway, agent-runtime, evals, prompt registry |
| Networking | match engine, intros |
| Analytics | ClickHouse, dashboards, metrics |
| Data/ML Platform | embeddings, model ops, cost (`12 §7`) |

**Key risks.** (1) WhatsApp quality-rating collapse from bad sends → channel death; (2) prompt injection at scale via
listing/knowledge content; (3) AI cost blowout; (4) marketplace trust/quality. **Mitigations:** send-pacing + consent
enforcement (`11 §1`); context isolation + injection corpus gates (`11 §7.4`, `13 §3`); AI caching/tiering + cost gates
(`12 §7`, `13 §3.3`); DTI-gated marketplace ranking.

**Exit criteria.** AI copilot DAU penetration ≥ 30% of MAU; WhatsApp quality rating stays "High"; marketplace GMV with
< 2% dispute rate; AI cost/MAU within model (`12 §7.3`); 5M users at SLO.

---

## Phase 3 — Multi-region + Enterprise + API/Developer Platform (Months 20–30)

**Goals.** Go global and go up-market. Enterprises (large referral orgs, franchises, associations) pay for admin,
compliance, SSO, analytics. Open a **developer API platform** so third parties build on the trust graph — the first
step toward becoming infrastructure.

**Modules shipped**
- Multi-region rollout: `eu-west-1`, `us-east-1` data planes; home-region residency enforced (`11 §8.1`, `12 §1,6`); cell splitting.
- Enterprise: org SSO (SAML/OIDC federation), org-admin console, org-scoped analytics, audit exports, DPA tooling, seat management, `org:finance/admin` (`11 §3`).
- **Developer/API platform:** public OpenAPI 3.1, OAuth client-credentials + fine-grained scopes (`11 §2`), API keys, rate tiers, webhooks, sandbox, docs; partner apps read (consented) trust/relationship signals.
- `notification-service` maturity; `media-service` scale; `search-service` cross-domain.
- Compliance hardening: SOC 2 Type II, GDPR/DPDP full posture, DPIA published (`11 §8`), India Consent Manager integration.

**Scale targets.** 25M users; Postgres sharding for largest domains, Neo4j Fabric, Redis Cluster, multi-cell per region (`12 §6`, 10M→50M).

**Team topology (90 → 130)**
| New/grown squad | Owns |
|---|---|
| Regions & Residency | cell topology, data residency, DR game days (`12 §5`) |
| Enterprise | SSO, admin console, org analytics |
| Developer Platform | public API, SDKs, webhooks, sandbox, DX |
| Compliance & Privacy | SOC2, GDPR/DPDP, DPIA, DPO office |
| Reliability (SRE) | SLOs, error budgets, chaos, on-call (`12 §4–5`) |

**Key risks.** (1) Data-residency complexity across cells; (2) API platform enabling scraping/abuse of the graph
(`11 §1` data-broker actor); (3) enterprise sales pulling roadmap toward services; (4) multi-region operational load.
**Mitigations:** cell architecture makes residency structural; strict consent + rate + watermark on API exports
(`11 §1.4`); enterprise features must be self-serve/product-led, not bespoke; SRE squad + game days before scaling further.

**Exit criteria.** 3 regions live at SLO with a passed region-loss game day (`12 §5.2`); SOC 2 Type II achieved; ≥ N
enterprise orgs live; developer platform with ≥ M active third-party apps; API abuse controls proven against red team.

---

## Phase 4 — Network-Effect Moats: TrustOS as Infrastructure (Months 30–36)

**Goals.** Make TrustOS trust *portable* and *foundational* — the moat is that a user's trust credential is valuable
*outside* TrustOS, and other networks/products depend on TrustOS for trust. Reach 100M.

**Modules shipped**
- **Portable trust credential:** user-controlled, verifiable trust attestations (verifiable-credentials style) a user can present elsewhere (a landlord, a lender, a marketplace) — with consent, revocation, and privacy-preserving disclosure (prove "Gold band" without revealing the graph).
- **TrustOS API for third parties (infra tier):** trust-as-a-service — other platforms query (consented) trust signals to reduce their own fraud; TrustOS becomes a trust-scoring backbone.
- Federation groundwork: interoperate with other reputation/identity networks (open problem #2 below).
- Global network-effects features: cross-community discovery, global business league, AI agent-to-agent networking (early).
- Scale hardening: many cells, hierarchical global leaderboards, AI cohort budgeting (`12 §6`, 50M→100M).

**Scale targets.** 100M users, 100 countries; cell = unit of scale, split at ~5–8M/cell (`12 §6`).

**Team topology (130 → 150)**
| New/grown squad | Owns |
|---|---|
| Trust Infrastructure | portable credentials, trust-as-a-service API |
| Federation | inter-network protocols, standards |
| Scale/Performance | sharding, leaderboard rollups, cost at 100M (`12 §7`) |
| Trust & Safety at scale | global abuse, algorithmic-reputation governance (`11 §8.2`) |

**Key risks.** (1) Portable trust invites Goodhart's law + fraud economy at higher stakes; (2) regulation of
algorithmic reputation (credit-like scrutiny); (3) federation standards immature; (4) 100M-scale cost/reliability.
**Mitigations:** contestability + human review scale-out (`11 §8.2`); proactive regulator engagement; start federation
with a narrow, well-specified interop; cost levers fully deployed (`12 §7.2`).

**Exit criteria.** Trust credential accepted by ≥ K external partners; trust-as-a-service API revenue material;
100M users at SLO with healthy infra cost/MAU (`12 §7.3`); algorithmic-reputation governance & appeals audited.

---

## What we deliberately do NOT build early (and why)

| Deferred | Why not early |
|---|---|
| **Full 15 modules at once** | Focus beats breadth; the BNI wedge must work before we generalize. Half-built modules erode trust. |
| **Multi-region / global from day 1** | Massive ops + residency cost for zero benefit at 50k users in one country. Single cell until ~1M (`12 §6`). |
| **Own payment rails / wallet** | Regulatory + PCI burden. Tokenize via PSP, stay SAQ-A (`11 §8.3`). Ledger is truth; PSP moves money. |
| **Self-hosted LLMs** | `ai-gateway` to Anthropic is cheaper/faster to ship and iterate; revisit GPU self-host only if cost/latency/residency forces it (`12 §1.2` GPU-optional). |
| **E2EE-everything (incl. AI on DMs by default)** | E2EE DMs are excluded from AI unless user opts in (`11 §4.4`); building AI-on-encrypted at scale early is premature. |
| **Public API / developer platform early** | Opening the trust graph before abuse controls mature invites scraping (`11 §1`). Phase 3, after residency + rate + watermark controls. |
| **Blockchain for trust** | A trust ledger doesn't need a blockchain; append-only PG + hash-chained audit (`11 §6`) gives integrity without the cost/latency/regulatory baggage. |
| **Marketplace before referrals** | Marketplace needs trust + liquidity that referrals/communities create first (open problem #5). |
| **Heavy gamification before real value** | Coins/badges without underlying business value trains vanity metrics — the exact anti-pattern `_brief` rejects. |

---

## The 5 Hardest Open Problems

1. **Portable trust.** Can a TrustOS score mean anything *off* TrustOS without becoming a shadow credit score? The
   hard parts: preventing Goodhart gaming when stakes rise, privacy-preserving disclosure (prove a band without the
   graph), revocation, and avoiding discriminatory misuse — all under emerging regulation (`11 §8.2`).

2. **Inter-network federation.** How do independent trust/reputation networks interoperate without a single point of
   control or a race to the bottom on standards? Requires portable, verifiable, non-repudiable trust claims and a
   protocol others adopt — a chicken-and-egg standards problem.

3. **Regulation of algorithmic reputation.** A trust score that gates economic opportunity will attract credit-bureau-
   style regulation (contestability, adverse-action notices, bias audits, right to explanation). Designing for this
   *now* (explainable DTI, appeals, human review — `11 §8.2`) is cheaper than retrofitting, but the legal landscape is
   unsettled across 100 countries.

4. **AI-agent-to-agent networking.** As users delegate to AI copilots, agents will negotiate intros, referrals, and
   deals with *other users' agents*. How do we keep that trustworthy — authenticated agent identity, provenance,
   collusion resistance between agents, and preventing an arms race of manipulative agents — while keeping humans in
   control of value movement (`11 §7.4`)?

5. **Marketplace liquidity.** Two-sided liquidity (supply of trusted referrers/sellers ↔ demand) is the classic
   cold-start; trust *helps* (reduces the risk premium) but doesn't create demand. Sequencing (referrals → communities
   → marketplace) is our bet, but sustaining liquidity per city/industry/community at 100M scale, without fraud
   hollowing it out, is unsolved and existential.

---

*End of 14-roadmap.md. Cross-refs: `11-security-architecture.md`, `12-devops-platform.md`, `13-testing-performance.md`.*
