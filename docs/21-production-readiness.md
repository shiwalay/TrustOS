# TrustOS — Production Readiness Plan (Integration + End-to-End Testing)

> What it takes to go from the current **demo** to a **production** system with real integrations and full E2E testing. Written honestly against what exists today, prioritized by a *critical path* — because "everything, in parallel" is how this fails.

## 0. Where we actually are (baseline)

| Layer | Built | Reality |
|---|---|---|
| Design docs | ✅ 20 docs | Comprehensive; the spec is ahead of the code |
| Backend | ⚠️ 1 of 25 services | Only `referral-service` + `trustos_core` are real (90 tests, runs on local Docker). The other 24 are designed, not coded |
| Mobile | ⚠️ UI complete, **not integrated** | Full Neo-Minimal app, but every screen runs on **seeded local Drift data** and has **never called the backend**. No real auth, no API client, no sync-to-server |
| Integrations | ❌ none | No payment aggregator, WhatsApp/SMS/email, KYC, Google/Outlook contact OAuth, LLM/ai-gateway, object storage |
| Infra | ⚠️ local only | Docker Compose on a laptop. No EKS, no managed stores, no CDN, no CI-to-deploy |
| Security/legal | ⚠️ designed | Auth/encryption/Cerbos/DPIA designed; ToS/privacy are draft; no pen test, no grievance officer, no DLT/TDS |
| Testing | ⚠️ unit only | Unit tests exist (referral domain + mobile widgets). **No integration, contract, E2E, load, or AI-eval tests** |

**One-line truth:** you can *demo* the whole vision, but you cannot put one real rupee or one real user's contacts through it. The distance between those is this document.

## 1. The critical path (thin production slice first)

Do **not** build 24 services before shipping anything. Build the **minimum vertical that carries a real referral end to end**, in production, with real money — then widen. That slice needs exactly these:

1. **`identity-service`** — the keystone. Real OIDC, ES256 JWT (15 min) + rotating refresh with reuse detection, device binding (DPoP), phone-OTP verification (T1), session revocation. *Everything gates on this.*
2. **Mobile ↔ backend wiring** — generate the Dart SDK from the OpenAPI spec, build the Dio/auth-interceptor stack for real, replace the referrals slice's stubbed remote source with real calls, implement the token vault (secure storage + biometric gate). This is the moment the app stops being a demo.
3. **`referral-service` hardening** (exists) + **`deal-service`** + **`ledger-service`** (double-entry) — the outcome + money ledger.
4. **Payment aggregator integration** (RBI-licensed PA) — escrow account, KYC/AML, payout at T4, TDS/PAN capture. Longest external lead time → **start partner conversations now**, in parallel.
5. **Minimum infra** — one region cell: managed Postgres, Redis, Kafka (MSK) + Debezium, Temporal, on EKS via ArgoCD; secrets in AWS SM; api-gateway + `bff-mobile`.
6. **The E2E test for this slice** (see §4): signup → phone-verify → submit referral → qualify → convert → escrow settle → payout, driven through the real API *and* the real app against staging.

Ship that to a closed pilot (Founding 100, doc 17). Then widen to the remaining services.

## 2. Backend — the remaining 24 services

Build order after the critical path, by dependency and value:

**Tier 1 (relationship core):** `profile-service`, `contact-service` (Google People + MS Graph + phone import, dedup/merge), `relationship-service` (+Neo4j), `trust-service` (DTI streaming compute + factor ledger). **Tier 2 (network/value):** `networking-service` (opportunity engine + **connector routing/scores**), `community-service`, `marketplace-service`, `automation-service` (Temporal). **Tier 3 (reach/AI):** `campaign-service` + `channel-service` (WhatsApp/email/SMS adapters), `ai-gateway` + `agent-runtime`, `knowledge-service`, `notification-service`. **Tier 4 (scale/insight):** `leaderboard-service`, `rewards-service`, `analytics-service` (ClickHouse), `search-service` (OpenSearch), `media-service`, `api-gateway`, `bff-mobile`.

Each service must ship with: Clean Architecture layers (per 03), Alembic schema (per 05), transactional outbox + Kafka events + idempotent consumers, gRPC (internal) + REST (public via gateway), Cerbos policies, OTel, and the test pyramid below. Use `referral-service` as the reference implementation.

## 3. Mobile — from seeded demo to real client

This is the single biggest "update" and is currently ~0% done:

- **API layer:** generate `trustos_api` Dart package from OpenAPI (spec-first, Spectral-linted) + a GraphQL client for the BFF; Dio with the real auth interceptor (bearer + DPoP), Problem-Details → `AppException` mapping, retry/backoff.
- **Auth:** real OIDC login, token vault (`flutter_secure_storage` + hardware keystore), refresh rotation, biometric unlock gating the vault, certificate pinning of the API CA.
- **Replace demo with real:** every repository's `remoteSource` (today a stub) calls real endpoints; delete `demo_seed` / `showDemoSnack` paths behind a flavor flag; the offline **sync engine** gets its server side — delta pull (cursor) + push (operation queue with idempotency keys), per-entity conflict policies (already designed).
- **Push:** FCM/APNs wired to `notification-service` (silent data pushes drive sync); deep links.
- **Observability:** Sentry + OTel from the client.

## 4. Testing — integration + end-to-end (the explicit ask)

The current suite is unit-only. Production needs the full pyramid, wired into CI as gates:

| Level | What | Tooling | Gate |
|---|---|---|---|
| **Unit** | Domain + application logic, per service; mobile domain/widgets | pytest, flutter test | 90%+ on domain/application layers |
| **Integration** | Each service against **real** Postgres/Kafka/Redis: repo ↔ DB, outbox → CDC → Kafka, idempotent consumer round-trips, Temporal activities | **testcontainers**, Temporal test env | Per-service CI |
| **Contract** | Consumer-driven contracts **between services** and **mobile SDK ↔ BFF/gateway**; Kafka schema-compat vs the registry | **Pact**, buf/oasdiff, schemathesis | Blocks breaking changes |
| **Saga / event** | Temporal workflow **replay** tests (referral settlement, automations); exactly-once boundaries; DLQ/retry behavior; chaos (toxiproxy) in staging | Temporal replay, toxiproxy | Per money/trust flow |
| **Backend E2E** | Spin the full (or sliced) stack; drive **critical journeys** through the API: signup→verify→refer→qualify→convert→escrow→payout; intro→meeting; campaign send→delivery webhook | docker-compose/vcluster + a black-box runner | Pre-release |
| **Mobile E2E** | Drive the **real app** against a **staging backend**: onboarding, referral submit→settle, **offline→online sync**, connector intro, campaign compose | **Patrol** / integration_test on device farm | Pre-release |
| **Synthetic probes** | The same critical journeys run continuously **against production** post-deploy | k6/synthetic monitors | Alerting |
| **Load / perf** | k6 scenarios (referral submit, feed, board), soak, capacity to target QPS; consumer-lag SLOs; mobile perf budgets | k6, Parca/py-spy | Cadence + pre-scale |
| **AI evals** | Golden datasets per prompt, LLM-as-judge + human calibration, regression on model upgrades, cost-regression | eval harness in CI | Blocks prompt/model promotion |
| **Security** | SAST (semgrep), deps (trivy), secrets scan, DAST, and a third-party **pen test** before handling money/PII | CI + external | Release + periodic |

**Critical-path E2E to write first** (the one that proves the thin slice works):
```
signup → OTP verify (T1) → submit referral (Idempotency-Key)
       → qualify → convert (deal) → commission escrowed
       → 14-day window → payout to bank (KYC/PAN)
       → outbox events emitted → trust score updated → app reflects it
```
Run it two ways: black-box through the API (backend E2E) **and** through the real Flutter app against staging (mobile E2E). Green on both = the slice is production-real.

**CI today vs needed:** the repo has a GitHub Actions workflow that lints/types/tests the `platform` workspace. Add: a **mobile CI job** (analyze + test + build), the integration/contract/E2E stages above, ephemeral PR environments (vcluster), and deploy gating (DB migration checks, canary analysis).

## 5. Integrations checklist (all external, all net-new)

- **Payments:** RBI-licensed payment aggregator (escrow/nodal, KYC/AML, payout, TDS). *No investment success fees — ever (16 §1).* Coins stay closed-loop.
- **Messaging:** WhatsApp Cloud API via a BSP (template approval, quality budgets), AWS SES (email + unsubscribe), SMS via a **DLT-registered** provider (DND), optional LinkedIn/Telegram.
- **Contact import:** Google People API + Microsoft Graph (Outlook) OAuth, native phone contacts (permission flows), CSV/CRM anti-corruption import.
- **Identity/KYC:** OTP/SMS provider; a KYC vendor for T4 (PAN/Aadhaar-eKYC where compliant).
- **AI:** Anthropic (Claude) via `ai-gateway`; an embeddings model; Qdrant.
- **Storage/edge:** S3 (private) + Cloudflare R2 (public media) + CDN/WAF/Turnstile.
- Each integration needs: sandbox creds, a real adapter in the owning service, failure/rate-limit handling, and integration tests against the sandbox.

## 6. Infra, security & compliance (production blockers)

**Infra:** provision the real data tier (Aurora/RDS Postgres, Neo4j cluster, Elasticache, MSK+Debezium, Qdrant, ClickHouse, Temporal Cloud or self-host) in one region cell on EKS; ArgoCD GitOps, Karpenter, Argo Rollouts canary; External Secrets + KMS; OTel → Prometheus/Grafana/Tempo/Loki + Sentry; backups/PITR + DR runbook (12).
**Security:** deploy Cerbos policies, device trust, cert pinning, field-level encryption + crypto-shredding, hash-chained audit log, mTLS mesh; run a pen test; begin SOC 2.
**Legal (must precede real money/PII):** execute ToS + Privacy + Referral Terms with counsel; DPIA on the trust score + contact graph; name a resident **Grievance Officer** (IT Rules) + in-app grievance surface; **DLT registration** before SMS; **TDS/PAN** at payout; non-member erasure web form; versioned acceptance logging (already in the app).

## 7. Sequencing & sizing (honest)

This maps to roadmap **Phase 0** (14): roughly **6–9 months with 8–15 engineers** to a real two-city pilot. Practical order:
1. **Weeks 0–2 (parallelizable):** start the payment-partner + BSP + KYC procurement (long lead); stand up one EKS cell + CI mobile job + the platform CI extensions.
2. **Months 1–3:** `identity-service` → **wire mobile to it** (real login is the first true integration) → harden `referral`/`deal`/`ledger` → payment integration → the critical-path backend+mobile E2E green.
3. **Months 3–6:** relationship core (profile/contact/relationship/trust) + `networking` (opportunity + connectors) + `notification` + contact-import OAuth; contract + E2E coverage per service; closed pilot.
4. **Months 6–9:** campaigns/channels + AI (ai-gateway/agents/evals) + communities/marketplace + analytics; load/soak/security tests; SOC 2 groundwork; scale the pilot.

## 8. Definition of "production-ready" (the checklist)

- [ ] Real user can sign up, verify, and log in (identity-service) from the real app
- [ ] App talks to the backend for **all** data (no seeded Drift in prod flavor); offline sync round-trips to the server
- [ ] A real referral settles and pays out real money through a licensed PA, with KYC/TDS
- [ ] Every service: unit + integration + contract tests green in CI; schema-compat enforced
- [ ] Critical-path E2E green through **both** API and the real app against staging; synthetic probes live in prod
- [ ] Deployed on EKS via GitOps with canary; SLOs + alerts + DR tested (game day)
- [ ] Security: Cerbos live, encryption + audit log, **pen test passed**
- [ ] Legal: ToS/privacy/referral executed, DPIA done, grievance officer + DLT + TDS in place
- [ ] AI: ai-gateway with budgets/guardrails, prompt eval gates in CI
- [ ] Cost per MAU within target (12 §7)

*Fastest first move: `identity-service` + wiring the mobile referrals slice to it + the critical-path E2E. That single vertical converts the demo into software — everything else widens from there.*

*Related: 03 (backend patterns), 04 (API/SDK), 12 (devops/scaling/cost), 13 (testing/perf), 14 (roadmap/sizing), 16 (legal blockers).*
