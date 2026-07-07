# 04 — API Design: Conventions, Endpoint Catalog, BFF Schema, Sequence Diagrams

> Conforms to `_shared-context.md` (binding). Siblings: `03-backend-architecture.md` (how services implement these APIs), `05-data-architecture.md` (schemas), `06-algorithms.md` (DTI/matching math), `11-security-architecture.md` (token & key details), `13-testing-performance.md` (contract testing).

Surfaces (shared-context §1): **REST** (OpenAPI 3.1) externally via `api-gateway`, **gRPC** service-to-service, **GraphQL** only at `bff-mobile` for aggregate reads. This document is the external contract:

- §1 Conventions · §2 Errors, rate limits, webhooks · §3 Endpoint catalog · §4 Six worked request/response examples · §5 GraphQL BFF · §6 Sequence diagrams (9 flows) · §7 OpenAPI governance.

---

## 1. API Conventions

### 1.1 Resource modeling

- Plural nouns, nesting max 2 deep: `/v1/communities/{communityId}/discussions`. Deeper relations get top-level resources with filters (`/v1/discussion-replies?filter[discussionId]=...`).
- **Verbs only as explicit state-transition sub-resources** on aggregates with lifecycles: `POST /v1/referrals/{id}/qualify`, `POST /v1/intro-requests/{id}/accept`. Never `PATCH status: "accepted"` — transitions carry semantics (authz, side effects, saga starts) that field patching hides.
- Long-running work returns **job resources**: `POST /v1/contact-imports` → `202 Accepted` + `Location: /v1/contact-imports/{jobId}`; clients poll or subscribe to push. Anything backed by Temporal (imports, campaign sends, KYC) follows this.
- IDs on the wire are the prefixed public IDs (`usr_`, `org_`, `cmt_`, `ref_`, `cmp_`, `dl_`, `evt_` — shared-context §1). JSON is camelCase; timestamps RFC 3339 UTC; money is `{"amountMinor": 250000, "currency": "INR"}` — never floats.
- Every write carries the **actor context**: `X-Acting-As: org:org_01hv...` header when a user acts as an org (defaults to the user principal). The gateway validates membership + role before forwarding as trusted claims.

### 1.2 Versioning

- Major version in path (`/v1/`), bumped only for breaking changes; target: never bump — evolve additively.
- Additive changes (new optional fields, new endpoints, new enum values) are **not** breaking; clients must tolerate unknown fields and unknown enum values (Dart SDK generates `unknown` fallbacks, §7.3).
- Breaking-change process: new `/v2/` endpoints run parallel ≥ 12 months; `Deprecation: true` + `Sunset: <RFC 3339>` + `Link: <successor>; rel="successor-version"` headers on `/v1/`; per-consumer usage tracked at the gateway so we deprecate with data, not hope (§7.4).

### 1.3 Authentication

Per shared-context §1 AuthN: OIDC, ES256 access JWT (15 min) + rotating refresh tokens (30 d, reuse detection), device-bound.

- `Authorization: Bearer <access_jwt>`; JWT claims: `sub` (usr_), `sid` (session), `dvc` (device id), `cnf.jkt` (DPoP key thumbprint), `scope`, `amr` (incl. `bio` after biometric unlock), `region`.
- **DPoP (RFC 9449)** on all mutating routes and all token-endpoint calls: client signs a `DPoP` proof JWT (per-request, `htm`+`htu`+`jti`+`ath`) with the device keypair generated in the mobile secure enclave at registration. A stolen bearer token is useless without the device key. Reads may omit DPoP (perf) except trust/ledger/identity reads which require it.
- Scopes are `resource:verb` (e.g. `referrals:write`, `trust:read`, `copilot:invoke`); coarse scopes gate at the gateway, fine-grained decisions are Cerbos policy checks in-service (shared-context §1 AuthZ). Machine clients (org integrations) use OAuth2 client-credentials with mTLS, scope-restricted API keys are **not** offered — keys leak.

### 1.4 Idempotency

`Idempotency-Key: <uuid>` required on every unsafe request the client may retry (all POSTs); stored 24 h in Redis (shared-context §5). Semantics — reserve / replay / conflict — are implemented once in `trustos-web` middleware (see `03-backend-architecture.md` §4.1): same key + same body ⇒ replayed response with `Idempotency-Replayed: true`; same key + different body ⇒ `422`; concurrent duplicate ⇒ `409` + `Retry-After`.

### 1.5 Pagination, filtering, sorting, search

- **Cursor pagination only** (shared-context §5): `?cursor=<opaque>&limit=25` (limit ≤ 100). Response envelope:

```json
{
  "data": [ ... ],
  "pageInfo": { "nextCursor": "eyJ2IjoxLCJrIjpb...", "hasMore": true }
}
```

Cursors are HMAC-signed base64 of `(sort key values, direction, filter hash)` — tamper or filter-drift ⇒ `400 invalid-cursor`.

- **Filter grammar** (JSON:API-flavored, one canonical form so SDK + Spectral can enforce it):

```
?filter[status]=qualified                    # equality
?filter[status]=qualified,converted          # IN
?filter[createdAt][gte]=2026-07-01T00:00:00Z # range: gte|gt|lte|lt
?filter[trustBand][gte]=silver               # ordered enums support ranges
?sort=-createdAt,commission                  # '-' = desc; whitelisted fields per endpoint
?q=priya+logistics                           # free-text — only on endpoints backed by search-service
?fields[referral]=id,status,commission       # sparse fieldsets (bandwidth-sensitive mobile paths)
```

Unknown filter/sort fields ⇒ `400 unknown-filter-field` listing allowed fields (fail loud, not silent-ignore — silent ignore corrupts client assumptions).

### 1.6 Concurrency

Mutable resources return `ETag` (aggregate `version`); `PATCH`/`PUT` require `If-Match`; mismatch ⇒ `412 stale-version` with the current version in the problem body.

---

## 2. Errors, Rate Limits, Webhooks

### 2.1 Problem Details (RFC 9457)

Every non-2xx body is `application/problem+json`:

```json
{
  "type": "https://api.trustos.com/problems/duplicate-referral",
  "title": "Duplicate referral",
  "status": 409,
  "detail": "An open referral for this prospect already exists on campaign cmp_01hv8p2e.",
  "instance": "/v1/referrals",
  "traceId": "4bf92f3577b34da6a3ce929d0e0e4736",
  "existingReferralId": "ref_01hv9k3d7q"
}
```

Canonical catalog (each `type` URL is a living doc page; extensions per problem are typed in the OpenAPI spec):

| slug | status | when |
|---|---|---|
| `validation-failed` | 400 | body/query fails schema; `errors[]` lists JSON-pointer + message |
| `invalid-cursor` / `unknown-filter-field` | 400 | pagination/filter grammar violations |
| `unauthenticated` | 401 | missing/expired/invalid token or DPoP proof |
| `token-reuse-detected` | 401 | refresh token replay — session family revoked (§6.2) |
| `permission-denied` | 403 | Cerbos deny; `requiredRole`/`requiredScope` hints when safe |
| `not-found` | 404 | absent OR unauthorized-to-know (no existence oracle) |
| `duplicate-referral`, `already-member`, `conflict` | 409 | business-state conflicts |
| `request-in-flight` | 409 | concurrent idempotent duplicate |
| `stale-version` | 412 | `If-Match` failed |
| `idempotency-key-reuse` | 422 | same key, different body |
| `insufficient-trust-band` | 422 | action gated on DTI band (`requiredBand`, `currentBand`) |
| `insufficient-balance` | 422 | ledger-gated actions (campaign budget, payout) |
| `rate-limited` | 429 | + `RateLimit-*` and `Retry-After` |
| `guardrail-blocked` | 422 | ai-gateway safety/guardrail rejection (`reasonCode`, never the raw prompt) |
| `upstream-degraded` | 503 | circuit open on a hard dependency; `Retry-After` |

### 2.2 Rate limiting

Token bucket at the gateway (per-user, per-org, per-IP — shared-context §5), tiers declared per endpoint in the catalog (§3) and machine-readable via `x-trustos-rate-tier` in OpenAPI:

| Tier | Default (per user) | Applied to |
|---|---|---|
| `auth` | 10/min per IP + per identifier | login, register, refresh, OTP |
| `read` | 600/min | GETs |
| `write` | 120/min | standard mutations |
| `bulk` | 10/min + 3 concurrent jobs | imports, exports, broadcast sends |
| `ai` | 30/min **and** metered token budget (plan-based, enforced by ai-gateway) | copilot, generation |

Draft-standard headers on every response: `RateLimit: limit=120, remaining=118, reset=27` + `RateLimit-Policy: 120;w=60`. 429s always include `Retry-After`. Org-level quotas aggregate across the org's members for `bulk`/`ai`.

### 2.3 Webhooks (org integrations + channel callbacks)

Orgs subscribe (`POST /v1/webhook-subscriptions`) to CloudEvents-shaped deliveries of public events (referral status, deal stage, campaign delivery, order events).

- **Signing:** `TrustOS-Signature: t=1751871600, v1=<hex hmac-sha256>` where `v1 = HMAC(secret, f"{t}.{raw_body}")`. Receivers must verify and reject `|now - t| > 300s` (replay window). Secrets per subscription, rotatable with dual-validity overlap of 24 h (`v1` new + `v1` old both sent during overlap).
- Delivery: at-least-once, exponential backoff over 24 h (8 attempts), then subscription auto-paused + notification. Receivers dedup on the CloudEvents `id`.
- `TrustOS-Webhook-Id` (delivery id) + `TrustOS-Event-Id` headers; test deliveries via `POST /v1/webhook-subscriptions/{id}/test`.

---

## 3. Endpoint Catalog

Notation: **Auth** = required scope (all endpoints require a bearer token unless marked `public`); **Tier** = rate tier (§2.2). Request/response columns list *key* fields only — full shapes live in `contracts/openapi/*.v1.yaml` (§7). All list endpoints support §1.5 grammar; all POSTs require `Idempotency-Key`; DPoP required on mutations (§1.3).

### 3.1 identity-service — `/v1/auth`, `/v1/devices`, `/v1/verifications`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/auth/register` | create account (phone or email first) | `phone\|email, displayName, country, dpopJwk, turnstileToken` → `userId, otpChallengeId` | public | auth |
| `POST /v1/auth/otp/verify` | verify OTP, activate account | `otpChallengeId, code` → token pair + `user` | public | auth |
| `POST /v1/auth/login` | password/OTP login | `identifier, password\|otp, deviceFingerprint` → tokens or `mfaChallengeId` | public | auth |
| `POST /v1/auth/mfa/verify` | complete MFA step | `mfaChallengeId, code\|assertion` → token pair | public | auth |
| `POST /v1/auth/token/refresh` | rotate refresh token | `refreshToken` (+DPoP) → new pair; reuse ⇒ 401 `token-reuse-detected` | public | auth |
| `POST /v1/auth/logout` | revoke session (or `?all=true` family) | — → 204 | any | auth |
| `GET /v1/devices` | list trusted devices | — → `[{deviceId, platform, lastSeenAt, trusted}]` | `devices:read` | read |
| `POST /v1/devices/{id}/revoke` | kill device sessions + keys | — → 204 | `devices:write` | write |
| `POST /v1/verifications/kyc` | start KYC (Temporal, §6.1) | `docType, docUploadId` → `202 {verificationId, status:"pending"}` | `identity:write` | bulk |
| `POST /v1/verifications/business` | GST / company / domain verification | `kind:"gst"\|"company"\|"domain", value` → `202 {verificationId}` | `org:admin` | bulk |
| `GET /v1/verifications/{id}` | poll verification status | → `{status, tier, failureReason?}` | `identity:read` | read |

### 3.2 profile-service — `/v1/profiles`, `/v1/orgs`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/profiles/me` | own profile | → full profile incl. preferences, tz | `profile:read` | read |
| `PATCH /v1/profiles/me` | update profile (`If-Match`) | `headline, bio, skills[], industries[], city` | `profile:write` | write |
| `GET /v1/profiles/{userId}` | public profile (visibility-filtered) | → `displayName, headline, trustBand, badges[]` | `profile:read` | read |
| `POST /v1/orgs` | create organization | `name, industry, country` → `org` | `org:create` | write |
| `GET /v1/orgs/{orgId}` / `PATCH` | org profile | | `org:read`/`org:admin` | read/write |
| `GET /v1/orgs/{orgId}/members` · `POST .../invitations` | membership mgmt | `role: owner\|admin\|member\|billing` | `org:admin` | write |

### 3.3 contact-service — `/v1/contacts`, `/v1/contact-imports`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/contact-imports` | start async import (§6.3) | `source:"google"\|"outlook"\|"phone"\|"csv"\|"hubspot"\|"zoho"\|"salesforce", authorizationCode\|uploadId` → `202 {jobId}` | `contacts:write` | bulk |
| `GET /v1/contact-imports/{jobId}` | job status | → `{status, imported, deduped, failed, progressPct}` | `contacts:read` | read |
| `GET /v1/contacts` | list/search own contacts | `?q=&filter[tag]=&filter[hasUser]=true` | `contacts:read` | read |
| `GET /v1/contacts/{id}` | contact detail + linked platform user | | `contacts:read` | read |
| `POST /v1/contacts` / `PATCH /v1/contacts/{id}` | manual create/edit | | `contacts:write` | write |
| `GET /v1/contacts/merge-suggestions` | AI dedup candidates | → `[{contactIds[], confidence, matchedOn[]}]` | `contacts:read` | read |
| `POST /v1/contacts/merges` | merge N contacts | `contactIds[], survivorId, fieldChoices{}` → merged contact | `contacts:write` | write |
| `DELETE /v1/contacts/{id}` | delete (crypto-shred PII refs) | → 204 | `contacts:write` | write |

### 3.4 relationship-service — `/v1/relationships`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/relationships` | list relationships | `?filter[scoreBand]=&sort=-score` | `relationships:read` | read |
| `GET /v1/relationships/{userId}` | relationship w/ specific user | → `{score, trend, reciprocity, lastInteractionAt}` | `relationships:read` | read |
| `GET /v1/relationships/{userId}/timeline` | interaction timeline | → events: meetings, messages, referrals, deals | `relationships:read` | read |
| `POST /v1/interactions` | log interaction (meeting/call/note) | `withUserId\|contactId, kind, occurredAt, notes` | `relationships:write` | write |
| `GET /v1/relationships/graph` | ego graph for viz | `?depth=2&minScore=40` → nodes/edges (capped 500) | `relationships:read` | read |
| `POST /v1/connections/{userId}` | request connection · `POST .../accept` | | `relationships:write` | write |

### 3.5 trust-service — `/v1/trust`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/trust/score` | own DTI | → `{score, band, percentile, updatedAt}` | `trust:read` | read |
| `GET /v1/trust/score/factors` | component breakdown (shared-context §4 weights) | → `[{component, weight, value, contribution, trend}]` | `trust:read` | read |
| `GET /v1/trust/score/history` | score over time | `?window=90d` → daily points | `trust:read` | read |
| `GET /v1/trust/score/explanation` | human-readable explanation (see §4.3) | → narrative + top movers, from trust_factor_ledger | `trust:read` | read |
| `GET /v1/trust/users/{userId}/band` | another user's band (band only — score is private) | → `{band}` | `trust:read` | read |
| `POST /v1/trust/vouches` | vouch for a user | `userId, context` → 201; transitively damped (§`06-algorithms.md`) | `trust:write` | write |
| `DELETE /v1/trust/vouches/{id}` | withdraw vouch | → 204 | `trust:write` | write |

### 3.6 networking-service — `/v1/recommendations`, `/v1/intro-requests`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/recommendations/people` | AI matches | `?filter[intent]=meet\|collab\|partner\|hire\|mentor\|invest` → `[{userId, reason, mutuals[], score}]` | `networking:read` | read |
| `POST /v1/recommendations/{id}/feedback` | accept/dismiss (feeds model) | `action:"interested"\|"dismissed", reason?` | `networking:write` | write |
| `POST /v1/intro-requests` | request intro via connector (§6.5) | `targetUserId, connectorUserId, context, message` → 201 | `networking:write` | write |
| `GET /v1/intro-requests?filter[role]=connector` | intros I'm asked to make | | `networking:read` | read |
| `POST /v1/intro-requests/{id}/accept` · `/decline` · `/forward` | connector actions | `note?` | `networking:write` | write |
| `POST /v1/intro-requests/{id}/meetings` | log/schedule resulting meeting | `scheduledAt, channel` → emits `networking.meeting.scheduled.v1` | `networking:write` | write |

### 3.7 referral-service — `/v1/referral-campaigns`, `/v1/referrals`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/referral-campaigns` | org creates campaign | `title, brief, scheme{fixed\|rateBasisPoints}, minReferrerBand, budget, window` | `org:admin` + `referrals:write` | write |
| `GET /v1/referral-campaigns` | browse (public, band-filtered) | `?filter[industry]=&filter[minBand][lte]=silver&q=` | `referrals:read` | read |
| `GET /v1/referral-campaigns/{id}` / `PATCH` / `POST .../publish` / `.../close` | lifecycle | publish requires funded budget (ledger check) | `org:admin` | write |
| `GET /v1/referral-campaigns/{id}/stats` | funnel stats (projection, `03-…` §2.6) | → `{submitted, qualified, converted, settled, conversionRate, commissionPaid}` | `org:read` | read |
| `POST /v1/referrals` | submit referral (see §4.2) | `campaignId, prospectContactId` → 201 `{id, status}` | `referrals:write` | write |
| `GET /v1/referrals` | my referrals (as referrer) or org inbox | `?filter[status]=&filter[campaignId]=` | `referrals:read` | read |
| `GET /v1/referrals/{id}` | detail + status timeline + commission | | `referrals:read` | read |
| `POST /v1/referrals/{id}/qualify` · `/reject` | org verdicts | `reason` on reject | `org:admin` | write |
| `GET /v1/referrals/{id}/settlement` | saga status (Temporal query passthrough) | → `{state:"dispute_window", disputeWindowEndsAt}` | `referrals:read` | read |
| `POST /v1/referrals/{id}/disputes` | raise dispute during window | `reason, evidenceUploadIds[]` → signals workflow | `org:admin` | write |

### 3.8 deal-service — `/v1/deals`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/deals` | create deal (optionally `referralId`, `introRequestId` for attribution) | `title, counterpartyContactId, expectedValue{Money}, stage` | `deals:write` | write |
| `GET /v1/deals` | pipeline | `?filter[stage]=&sort=-expectedValue` | `deals:read` | read |
| `POST /v1/deals/{id}/stage` | advance stage: `intro→meeting→proposal→negotiation→won\|lost` | `stage, note` → emits `deal.stage.changed.v1` | `deals:write` | write |
| `POST /v1/deals/{id}/invoices` | issue invoice | `amount{Money}, dueAt` → `deal.invoice.issued.v1` | `deals:write` | write |
| `POST /v1/invoices/{id}/mark-paid` | record payment (verified via ledger where possible) | → `deal.invoice.paid.v1` (feeds DTI transaction component) | `deals:write` | write |
| `GET /v1/deals/summary` | revenue/attribution rollup | `?window=quarter` | `deals:read` | read |

### 3.9 campaign-service + channel-service — `/v1/campaigns`, `/v1/channels`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/campaigns` | create campaign (see §4.4) | `name, channel:"whatsapp"\|"email"\|"sms"\|"linkedin"\|"telegram", audience{filter}, content{templateId\|aiBrief}, schedule` | `campaigns:write` | write |
| `GET /v1/campaigns` / `GET /{id}` / `PATCH /{id}` | manage drafts | | `campaigns:read/write` | read/write |
| `POST /v1/campaigns/{id}/preview` | render personalization for N sample recipients | → `[{recipientId, renderedBody}]` | `campaigns:write` | write |
| `POST /v1/campaigns/{id}/send` | schedule/launch (Temporal, §6.6) | `sendAt?` → `202 {runId}` | `campaigns:send` | bulk |
| `GET /v1/campaigns/{id}/analytics` | funnel: sent/delivered/read/replied/failed | | `campaigns:read` | read |
| `GET /v1/campaigns/{id}/messages` | per-recipient statuses | `?filter[status]=failed` | `campaigns:read` | read |
| `POST /v1/channels/whatsapp/connect` | connect WABA (embedded signup) | `wabaId, phoneNumberId, accessCode` | `org:admin` | write |
| `GET /v1/channels` | connected channels + quality rating | → `[{channel, status, qualityRating, dailyLimit}]` | `campaigns:read` | read |
| `POST /v1/channels/whatsapp/templates` | submit template for Meta approval | `name, language, components[]` → `202 {templateId, status:"pending"}` | `campaigns:write` | write |
| `GET /v1/channels/whatsapp/templates` | template list + approval status | | `campaigns:read` | read |

### 3.10 community-service — `/v1/communities`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/communities` | create (band-gated: Silver+) | `name, kind:"mastermind"\|"industry"\|"location"\|"private"\|"referral", visibility` | `communities:create` | write |
| `GET /v1/communities` / `GET /{id}` | discover/detail | `?q=&filter[kind]=&filter[city]=` | `communities:read` | read |
| `POST /v1/communities/{id}/join-requests` · `POST .../members/{userId}/approve` | membership | | `communities:write` / cmty admin | write |
| `GET /v1/communities/{id}/discussions` · `POST` | discussion threads | `title, body, tags[]` | member | read/write |
| `POST /v1/discussions/{id}/replies` · `POST .../reactions` | thread activity | | member | write |
| `GET /v1/communities/{id}/events` · `POST` | community events | `title, startsAt, venue\|meetingUrl, capacity` | member / cmty admin | read/write |
| `POST /v1/events/{id}/rsvps` · `POST /v1/events/{id}/check-ins` | attend (check-in feeds DTI consistency) | | member | write |
| `GET /v1/communities/{id}/leaderboard` | community trust ranking (leaderboard-service data) | | member | read |
| `GET /v1/communities/{id}/referral-board` | community referral needs/offers | | member | read |

### 3.11 marketplace-service — `/v1/listings`, `/v1/orders`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/listings` | create listing | `kind:"service"\|"product"\|"course"\|"consulting"\|"job"\|"partnership"\|"event", title, price{Money}?, description` | `marketplace:write` | write |
| `GET /v1/listings` | search (OpenSearch-backed) | `?q=&filter[kind]=&filter[city]=&filter[sellerBand][gte]=` | `marketplace:read` | read |
| `POST /v1/listings/{id}/publish` / `.../archive` | lifecycle | | owner | write |
| `POST /v1/listings/{id}/offers` | buyer makes offer/inquiry | `message, proposedPrice{Money}?` | `marketplace:write` | write |
| `POST /v1/orders` | place order (escrow via ledger for eligible categories) | `listingId, offerId?` → 201 | `marketplace:write` | write |
| `POST /v1/orders/{id}/complete` · `/disputes` | fulfilment endpoints | completion emits `marketplace.order.completed.v1` | parties | write |

### 3.12 knowledge-service — `/v1/knowledge`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/knowledge/items` | publish item | `kind:"article"\|"video"\|"template"\|"prompt"\|"sop"\|"playbook"\|"case_study", title, body\|mediaId, tags[]` | `knowledge:write` | write |
| `GET /v1/knowledge/items` | browse/search | `?q=&filter[kind]=&sort=-endorsements` | `knowledge:read` | read |
| `GET /v1/knowledge/items/{id}` | read (records `knowledge.item.consumed.v1`) | | `knowledge:read` | read |
| `POST /v1/knowledge/items/{id}/endorsements` | endorse (feeds DTI knowledge component) | | `knowledge:write` | write |
| `GET /v1/knowledge/prompt-library` | curated prompts for copilot | `?filter[useCase]=` | `knowledge:read` | read |

### 3.13 rewards-service + leaderboard-service — `/v1/rewards`, `/v1/leaderboards`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/rewards/balance` | coins (ledger-backed) + XP + level | → `{coins{Money-like}, xp, level, nextLevelAt}` | `rewards:read` | read |
| `GET /v1/rewards/ledger` | coin/XP history | cursor over ledger entries | `rewards:read` | read |
| `GET /v1/rewards/badges` | earned + available badges, streaks | | `rewards:read` | read |
| `POST /v1/rewards/redemptions` | redeem coins (catalog item) | `catalogItemId` → ledger movement | `rewards:write` | write |
| `GET /v1/leaderboards/{period}/{scope}` | e.g. `/weekly/city:pune`, `/monthly/community:cmt_x`, `/annual/global` | `?around=me&limit=25` → ranks + own rank | `leaderboards:read` | read |
| `GET /v1/leaderboards/{period}/{scope}/me` | own rank + delta | | `leaderboards:read` | read |

Periods: `daily|weekly|monthly|quarterly|annual`; scopes: `global`, `country:{iso}`, `city:{slug}`, `industry:{slug}`, `community:{id}`, `company:{orgId}` (brief module 11).

### 3.14 automation-service — `/v1/automations`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/automations/templates` | system templates (birthday, follow-up, drip, journey, festival, meeting-reminder, referral-reminder) | | `automations:read` | read |
| `POST /v1/automations` | create from template or custom | `trigger{kind, params}, steps[{action, params, delay}]` | `automations:write` | write |
| `POST /v1/automations/{id}/enable` · `/disable` | lifecycle | | `automations:write` | write |
| `GET /v1/automations/{id}/runs` | run history (Temporal-backed) | → `[{runId, status, startedAt, stepResults[]}]` | `automations:read` | read |
| `POST /v1/automation-runs/{runId}/cancel` | cancel in-flight run | | `automations:write` | write |

### 3.15 ai-gateway / agent-runtime (public copilot surface) — `/v1/copilot`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `POST /v1/copilot/messages` | generate message/content (see §4.6, §6.9) | `intent, context{...}, tone, channel` → generated variants + `generationId` | `copilot:invoke` | ai |
| `POST /v1/copilot/campaigns/draft` | draft full campaign (copy + image brief) | `goal, audienceHint` → draft campaign object | `copilot:invoke` | ai |
| `POST /v1/copilot/summaries` | summarize meeting/thread/relationship | `sourceKind, sourceId\|transcriptUploadId` | `copilot:invoke` | ai |
| `POST /v1/copilot/predictions/referral` | predict referral conversion likelihood | `referralId` → `{probability, drivers[]}` | `copilot:invoke` | ai |
| `POST /v1/copilot/predictions/clv` | predict CLV for a relationship | `contactId\|userId` | `copilot:invoke` | ai |
| `GET /v1/copilot/followups` | recommended follow-ups today | → prioritized list w/ reasons | `copilot:read` | read |
| `POST /v1/copilot/generations/{id}/feedback` | 👍/👎 + edit-distance capture → `ai.feedback.recorded.v1` | `rating, finalText?` | `copilot:invoke` | write |

### 3.16 notification-service — `/v1/notifications`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/notifications` | in-app inbox | `?filter[read]=false` | `notifications:read` | read |
| `POST /v1/notifications/read` | mark read | `ids[]\|all:true` | `notifications:write` | write |
| `GET /v1/notification-preferences` / `PUT` | preference center (per category × channel incl. quiet hours) | | `notifications:*` | read/write |
| `POST /v1/push-tokens` | register FCM/APNs token (per device) | `platform, token` | `notifications:write` | write |

### 3.17 analytics-service — `/v1/analytics`

| Method & Path | Purpose | Key request → response | Auth | Tier |
|---|---|---|---|---|
| `GET /v1/analytics/dashboards/business` | revenue, deals, referral earnings over time | `?window=90d&granularity=week` | `analytics:read` | read |
| `GET /v1/analytics/dashboards/relationships` | network growth, reciprocity, at-risk relationships | | `analytics:read` | read |
| `GET /v1/analytics/dashboards/trust` | DTI trend vs percentile, component trends | | `analytics:read` | read |
| `GET /v1/analytics/dashboards/campaigns` | cross-campaign funnels | | `analytics:read` | read |
| `GET /v1/analytics/dashboards/community/{id}` | community health (admin) | | cmty admin | read |
| `POST /v1/analytics/queries` | saved-metric query (definition-based, not raw SQL) | `metricId, dimensions[], window` | `analytics:read` | read |

Also public-facing but thin: `media-service` (`POST /v1/uploads` → presigned URL + `uploadId`, `GET /v1/media/{id}` → CDN URL) and `search-service` (`GET /v1/search?q=&filter[type]=people,listings,knowledge` — federated results).

---

## 4. Worked Examples (the 6 most important endpoints)

### 4.1 `POST /v1/auth/register`

```http
POST /v1/auth/register HTTP/1.1
Content-Type: application/json
Idempotency-Key: 8f14e45f-ceea-467f-a0e6-b2c1a4c1f8a2
DPoP: eyJ0eXAiOiJkcG9wK2p3dCIsImFsZyI6IkVTMjU2Iiwiandr...
```
```json
{
  "phone": "+919812345678",
  "displayName": "Priya Sharma",
  "country": "IN",
  "dpopJwk": { "kty": "EC", "crv": "P-256", "x": "f83OJ3D2xF1Bg8vub9tLe1gHMzV76e8Tus9uPHvRVEU", "y": "x_FEzRu9m36HLN_tue659LNpXW6pCyStikYjKIWI5a0" },
  "turnstileToken": "0.4AAAAAABkT0v..."
}
```
`201 Created`
```json
{
  "userId": "usr_01hv8x9k2mqw3r4t5y6u7i8o9p",
  "otpChallengeId": "otp_01hv8x9k3a",
  "otpExpiresAt": "2026-07-07T10:05:00Z",
  "homeRegion": "ap-south-1"
}
```
Errors: `409 conflict` (identifier registered — response identical in timing to success path pre-check to avoid enumeration; delivered via OTP flow), `400 validation-failed`, `429 rate-limited`.

### 4.2 `POST /v1/referrals`

```http
POST /v1/referrals HTTP/1.1
Authorization: Bearer eyJhbGciOiJFUzI1NiIs...
DPoP: eyJ0eXAiOiJkcG9wK2p3dCIs...
Idempotency-Key: 6c9d0d3a-2b1e-4a7f-9c3d-1f2e3a4b5c6d
```
```json
{
  "campaignId": "cmp_01hv8p2e9krw",
  "prospectContactId": "cnt_01hv8q7t3xzn",
  "note": "CFO of a 200-person logistics firm in Pune; actively evaluating GST software."
}
```
`201 Created`
```json
{
  "id": "ref_01hv9k3d7qab",
  "status": "submitted",
  "campaignId": "cmp_01hv8p2e9krw",
  "schemeSnapshot": { "rateBasisPoints": 500, "minReferrerBand": "silver" },
  "potentialCommission": null,
  "submittedAt": "2026-07-07T10:12:31Z",
  "links": { "self": "/v1/referrals/ref_01hv9k3d7qab", "campaign": "/v1/referral-campaigns/cmp_01hv8p2e9krw" }
}
```
Errors: `409 duplicate-referral` (+ `existingReferralId`), `422 insufficient-trust-band` (`{"requiredBand":"silver","currentBand":"bronze"}`), `404 not-found` (campaign closed/unpublished).

### 4.3 `GET /v1/trust/score/explanation`

`200 OK`
```json
{
  "score": 712,
  "band": "gold",
  "percentile": 91.4,
  "updatedAt": "2026-07-07T04:00:12Z",
  "components": [
    { "component": "referralPerformance", "weight": 0.20, "value": 0.81, "contribution": 162, "trend": "up",
      "explanation": "9 of 12 qualified referrals converted in the last 180 days (Wilson-smoothed)." },
    { "component": "identityVerification", "weight": 0.15, "value": 0.90, "contribution": 135, "trend": "flat",
      "explanation": "KYC tier 2, GST verified, domain verified. Add social verification for the last 0.10." },
    { "component": "relationshipQuality", "weight": 0.15, "value": 0.62, "contribution": 93, "trend": "up",
      "explanation": "High reciprocity across 34 active relationships; diversity across 6 industries." }
  ],
  "topMovers": [
    { "at": "2026-07-05T09:14:00Z", "event": "referral.commission.settled.v1", "delta": +6,
      "detail": "Referral to Meridian Logistics settled (₹45,000 deal)." },
    { "at": "2026-07-02T18:00:00Z", "event": "trust.factor.recorded.v1", "delta": -3,
      "detail": "Missed confirmed meeting (promise-keeping factor)." }
  ]
}
```
Every line traces to rows in the append-only `trust_factor_ledger` (shared-context §4: explainable and auditable). The narrative strings are template-rendered server-side, not LLM-generated — explanations must be deterministic and reproducible.

### 4.4 `POST /v1/campaigns` (WhatsApp)

```json
{
  "name": "Diwali greetings — top 50 clients",
  "channel": "whatsapp",
  "audience": { "filter": { "tag": "client", "relationshipScore": { "gte": 60 } }, "estimatedSize": 47 },
  "content": {
    "templateId": "wat_01hv7m2k",
    "personalization": { "1": "{{contact.firstName}}", "2": "{{ai.festivalLine}}" },
    "aiPersonalizationBrief": "Warm one-line Diwali wish referencing our business relationship; no salesy tone."
  },
  "schedule": { "sendAt": "2026-10-29T04:30:00Z", "timezoneStrategy": "recipientLocal", "localTime": "10:00" }
}
```
`201 Created` → campaign object with `status: "draft"`, `estimatedCost: {"amountMinor": 41360, "currency": "INR"}` (Meta conversation pricing + platform fee), and `warnings: ["Template wat_01hv7m2k is approved for MARKETING category; quality rating currently HIGH"]`. Launch is a separate `POST /{id}/send` (§6.6).

### 4.5 `POST /v1/intro-requests`

```json
{
  "targetUserId": "usr_01hv2a8b9c",
  "connectorUserId": "usr_01hv5d6e7f",
  "context": "raising_seed_round",
  "message": "Rohan, you know Anita from the Pune SaaS mastermind — would you introduce us? We're raising and her fund leads pre-seed in logistics tech."
}
```
`201 Created`
```json
{
  "id": "int_01hvax4y5z",
  "status": "pending_connector",
  "expiresAt": "2026-07-14T10:12:31Z",
  "connectorTrustContext": { "connectorToTargetBand": "gold", "relationshipStrength": "strong" }
}
```
Errors: `422 insufficient-trust-band` (intro requests need Bronze+), `409 conflict` (open request to same target already exists).

### 4.6 `POST /v1/copilot/messages`

```json
{
  "intent": "follow_up_after_meeting",
  "context": { "contactId": "cnt_01hv8q7t3xzn", "meetingId": "mtg_01hvb2c3", "dealId": "dl_01hvb9x8" },
  "tone": "warm_professional",
  "channel": "whatsapp",
  "variants": 2,
  "language": "en-IN"
}
```
`200 OK`
```json
{
  "generationId": "gen_01hvbq4r5s",
  "variants": [
    { "text": "Hi Priya, great connecting today. As promised, I'm sending over the GST-module comparison by Thursday. One question I forgot — is the Pune warehouse rollout still targeted for Q3?", "safety": "passed" },
    { "text": "Priya, thank you for the time today — the point about consolidating your 3PL invoicing stuck with me. I'll send the comparison sheet by Thursday and set up the demo with our solutions lead.", "safety": "passed" }
  ],
  "grounding": { "sourcesUsed": ["meeting_summary:mtg_01hvb2c3", "relationship_timeline:cnt_01hv8q7t3xzn"] },
  "usage": { "model": "claude-sonnet-5", "inputTokens": 1841, "outputTokens": 212, "budgetRemainingPct": 84 }
}
```
Errors: `422 guardrail-blocked` (`reasonCode: "pii_exfiltration" | "impersonation" | "prohibited_content"`), `429 rate-limited` (token budget exhausted → `budgetResetsAt`).

---

## 5. GraphQL BFF (`bff-mobile`)

### 5.1 Why GraphQL, and why *only* here

The Flutter home screen needs profile + DTI + feed + follow-ups + notifications + leaderboard rank: 6 REST calls, 6 round trips on Indian mobile networks. The BFF collapses each screen into **one query shaped exactly like the screen**. GraphQL is confined to `bff-mobile` because: (a) it's read-only aggregation — **all mutations stay REST** (idempotency keys, DPoP, Problem Details, webhooks are REST-native and we refuse to duplicate that machinery); (b) public GraphQL invites unbounded queries from third parties — internally we control every persisted query; (c) service teams keep OpenAPI/gRPC contracts as their single source of truth; the BFF is just another consumer. Federation (Apollo-style subgraphs per service) was rejected: it drags GraphQL into every service team's contract surface for exactly one consumer. A single strawberry-python schema owned by the mobile team, resolving over downstream **gRPC** (not REST — saves a serialization hop), is simpler and fast enough.

Operational guardrails: **persisted queries only** in production (allow-list shipped with each app release), depth ≤ 8, complexity budget per query, `APQ` for preview builds.

### 5.2 SDL — `contracts/graphql/bff-mobile.graphql`

```graphql
schema { query: Query }

scalar DateTime          # RFC 3339
scalar Cursor

type Query {
  home: HomeScreen!                     # single query for app launch
  dashboard(window: AnalyticsWindow! = D90): DashboardScreen!
  profile(userId: ID): ProfileScreen!   # null = self
  community(id: ID!): CommunityScreen!
}

# ---------- Home ----------
type HomeScreen {
  me: Viewer!
  feed(cursor: Cursor, limit: Int! = 20): FeedConnection!
  followUps(limit: Int! = 5): [FollowUp!]!          # copilot recommendations
  unreadNotifications: Int!
}

type Viewer {
  id: ID!
  displayName: String!
  avatarUrl: String
  trust: TrustSummary!
  rewards: RewardsSummary!
}

type TrustSummary {
  score: Int!
  band: TrustBand!
  percentile: Float!
  weeklyDelta: Int!
}

enum TrustBand { STARTER BRONZE SILVER GOLD PLATINUM }

type RewardsSummary { xp: Int!, level: Int!, coins: Int!, streakDays: Int! }

type FeedConnection { edges: [FeedItem!]!, nextCursor: Cursor, hasMore: Boolean! }

union FeedItem =
    RecommendationCard      # networking match
  | ReferralOpportunityCard # open campaign matched to viewer
  | CommunityActivityCard
  | RelationshipNudgeCard   # "You haven't spoken to Anita in 6 weeks"
  | KnowledgeCard
  | LeaderboardMoveCard

type RecommendationCard {
  id: ID!
  person: PersonSummary!
  intent: MatchIntent!
  reason: String!
  mutualCount: Int!
}
enum MatchIntent { MEET COLLAB PARTNER HIRE MENTOR INVEST }

type ReferralOpportunityCard {
  id: ID!
  campaign: CampaignSummary!
  fitReason: String!
  potentialCommission: Money
}
type CampaignSummary { id: ID!, title: String!, org: OrgSummary!, minReferrerBand: TrustBand! }
type Money { amountMinor: Int!, currency: String! }

type FollowUp { id: ID!, contact: PersonSummary!, reason: String!, suggestedAction: String!, dueAt: DateTime }

# ---------- Dashboard ----------
enum AnalyticsWindow { D30 D90 D365 }
type DashboardScreen {
  business: BusinessMetrics!            # analytics-service (ClickHouse)
  trustTrend: [TrustPoint!]!
  pipeline: PipelineSummary!            # deal-service
  referralEarnings: Money!
  leaderboard: LeaderboardPosition!
}
type BusinessMetrics { revenue: Money!, dealsWon: Int!, introsMade: Int!, meetingsHeld: Int! }
type TrustPoint { date: DateTime!, score: Int! }
type PipelineSummary { open: Int!, weightedValue: Money!, stalled: Int! }
type LeaderboardPosition { scope: String!, period: String!, rank: Int!, delta: Int! }

# ---------- Profile ----------
type ProfileScreen {
  person: PersonDetail!
  relationship: RelationshipContext     # null when viewing self
  sharedCommunities: [CommunitySummary!]!
  recentKnowledge: [KnowledgeItemSummary!]!
  badges: [Badge!]!
}
type PersonDetail { id: ID!, displayName: String!, headline: String, city: String,
                    industries: [String!]!, trustBand: TrustBand!, avatarUrl: String }
type PersonSummary { id: ID!, displayName: String!, headline: String, trustBand: TrustBand!, avatarUrl: String }
type RelationshipContext { score: Int!, trend: Trend!, lastInteractionAt: DateTime,
                           mutuals: [PersonSummary!]!, timeline(limit: Int! = 10): [TimelineEvent!]! }
enum Trend { UP FLAT DOWN }
type TimelineEvent { at: DateTime!, kind: String!, summary: String! }
type Badge { id: ID!, name: String!, iconUrl: String!, earnedAt: DateTime! }

# ---------- Community ----------
type CommunityScreen {
  community: CommunityDetail!
  membership: MembershipContext!
  discussions(cursor: Cursor, limit: Int! = 20): DiscussionConnection!
  upcomingEvents: [EventSummary!]!
  leaderboard(limit: Int! = 10): [LeaderboardEntry!]!
  referralBoard(limit: Int! = 10): [ReferralBoardItem!]!
}
type CommunityDetail { id: ID!, name: String!, kind: String!, memberCount: Int!, description: String }
type MembershipContext { isMember: Boolean!, role: String, joinedAt: DateTime }
type DiscussionConnection { edges: [Discussion!]!, nextCursor: Cursor, hasMore: Boolean! }
type Discussion { id: ID!, title: String!, author: PersonSummary!, replyCount: Int!, lastActivityAt: DateTime! }
type EventSummary { id: ID!, title: String!, startsAt: DateTime!, rsvpCount: Int!, viewerRsvped: Boolean! }
type LeaderboardEntry { rank: Int!, person: PersonSummary!, score: Int! }
type ReferralBoardItem { id: ID!, kind: String!, title: String!, postedBy: PersonSummary! }
type CommunitySummary { id: ID!, name: String!, memberCount: Int! }
type OrgSummary { id: ID!, name: String!, logoUrl: String, verified: Boolean! }
type KnowledgeItemSummary { id: ID!, kind: String!, title: String!, endorsements: Int! }
```

### 5.3 N+1 / dataloader strategy

- Every downstream fetch goes through a **request-scoped DataLoader** keyed by (service, entity, id): `PersonSummaryLoader`, `TrustBandLoader`, `RelationshipLoader`, etc. A feed page with 20 cards referencing 20 people = **one** `profile.GetProfilesBatch` gRPC call + **one** `trust.GetBandsBatch` call. Every internal gRPC read used by the BFF has a mandatory `Batch` variant (contract rule enforced in buf lint config).
- Loaders sit on top of a request-local cache, then Redis for hot entities (profile summaries, trust bands: 60 s TTL — staleness acceptable for display; anything transactional goes to REST).
- Resolver fan-out for a screen's top-level fields runs concurrently (`asyncio.gather`); per-request downstream budget: ≤ 12 unary calls, enforced by a middleware counter that fails the query in dev/staging and alerts in prod.
- Partial degradation: each top-level screen field resolves independently; a trust-service brownout returns `trust: null` + an `errors[]` entry with `extensions.degraded: true`, and the app renders a placeholder — one slow service never blanks the home screen.

---

## 6. Sequence Diagrams

### 6.1 Signup + KYC verification

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter app
    participant GW as api-gateway
    participant ID as identity-service
    participant T as Temporal (kyc ns)
    participant KYCP as KYC provider (ACL)
    participant K as Kafka
    participant TR as trust-service

    App->>App: generate device keypair (secure enclave)
    App->>GW: POST /v1/auth/register (dpopJwk, turnstileToken)
    GW->>GW: Turnstile verify, IP rate limit
    GW->>ID: forward
    ID->>ID: create user (uuid7), bind device key, send OTP
    ID-->>App: 201 {userId, otpChallengeId}
    App->>GW: POST /v1/auth/otp/verify {code} + DPoP
    GW->>ID: forward
    ID->>ID: activate; outbox: identity.user.registered.v1
    ID-->>App: 200 {accessToken, refreshToken}
    Note over ID,K: Debezium → Kafka
    K-->>TR: identity.user.registered.v1 → DTI bootstrap (Starter band)

    App->>GW: POST /v1/uploads (KYC doc) → media-service presigned URL
    App->>GW: POST /v1/verifications/kyc {docType, docUploadId}
    GW->>ID: forward
    ID->>T: start KycWorkflow(id=f"kyc-{userId}")
    ID-->>App: 202 {verificationId, status: pending}
    T->>KYCP: activity: submit doc (via anti-corruption translator)
    KYCP-->>T: webhook → signal: provider_result(approved, tier=2)
    T->>ID: activity: record result; outbox identity.kyc.completed.v1
    K-->>TR: identity.kyc.completed.v1 → identity factor s₁ ↑ (weight 0.15)
    TR->>K: trust.score.updated.v1
    K-->>App: (via notification-service push) "You're verified — DTI +45"
```

### 6.2 Login with device trust + biometric

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter app
    participant SE as Secure enclave
    participant GW as api-gateway
    participant ID as identity-service

    App->>GW: POST /v1/auth/login {identifier, otp, deviceFingerprint} + DPoP(device key)
    GW->>ID: forward
    ID->>ID: verify credentials; device key known? risk score (new geo? new device?)
    alt known + trusted device (identity.device.trusted.v1 previously emitted)
        ID-->>App: 200 tokens (amr: ["otp","dvc"])
    else new / risky device
        ID-->>App: 401 mfaChallengeId (step-up)
        App->>GW: POST /v1/auth/mfa/verify {challenge, code}
        GW->>ID: verify → mark device trusted → outbox identity.device.trusted.v1
        ID-->>App: 200 tokens
    end
    Note over App,SE: later: app cold start
    App->>SE: biometric prompt → unlock device private key
    SE-->>App: key handle (never leaves enclave)
    App->>GW: POST /v1/auth/token/refresh {refreshToken} + DPoP proof signed w/ unlocked key
    GW->>ID: forward
    ID->>ID: rotate refresh token (family check)
    alt token already used (theft)
        ID->>ID: revoke entire session family
        ID-->>App: 401 token-reuse-detected → full re-auth
    else
        ID-->>App: 200 new pair (amr includes "bio")
    end
```

### 6.3 Contact import (async job via Temporal)

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter app
    participant GW as api-gateway
    participant CS as contact-service
    participant T as Temporal (contact-import ns)
    participant G as Google People API (ACL)
    participant K as Kafka
    participant RS as relationship-service

    App->>GW: POST /v1/contact-imports {source:"google", authorizationCode}
    GW->>CS: forward
    CS->>T: start ContactImportWorkflow(id=f"import-{userId}-{jobId}")
    CS-->>App: 202 {jobId} + Location
    loop paged fetch (activity per page, heartbeat + resume cursor)
        T->>G: fetch page (rate-limit aware, translator → CanonicalContact)
        T->>CS: activity: upsert batch (dedup key: normalized phone/email)
    end
    T->>CS: activity: run merge-suggestion pass (blocking keys → candidate pairs)
    T->>CS: activity: finalize; outbox contact.import.completed.v1 {imported, deduped, failed}
    K-->>RS: contact.import.completed.v1 → seed relationship records for matched platform users
    K-->>App: push "312 contacts imported, 9 merge suggestions"
    App->>GW: GET /v1/contact-imports/{jobId} → {status:"completed", imported:312, deduped:9}
```

### 6.4 Referral submit → qualify → convert → commission settle (cross-service saga)

```mermaid
sequenceDiagram
    autonumber
    participant Ref as Referrer app
    participant Org as Org dashboard
    participant RS as referral-service
    participant TS as trust-service
    participant DS as deal-service
    participant T as Temporal (referral ns)
    participant LG as ledger-service
    participant RW as rewards-service
    participant K as Kafka

    Ref->>RS: POST /v1/referrals {campaignId, prospectContactId}
    RS->>TS: gRPC GetBand(referrer) — band gate
    RS->>RS: Referral.submit(); tx: row + outbox(referral.referral.submitted.v1)
    RS-->>Ref: 201 {id, status: submitted}
    K-->>Org: (notification) new referral to review
    Org->>RS: POST /v1/referrals/{id}/qualify
    RS->>RS: qualify(); outbox referral.referral.qualified.v1

    Note over DS: weeks later — org wins the deal linked to this referral
    DS->>DS: deal won; outbox deal.deal.won.v1 {dealId, referralId, value}
    K-->>RS: consumer: convert(dealId, value) → commission computed → outbox referral.referral.converted.v1
    RS->>T: start ReferralSettlementWorkflow(id=f"settle-{referralId}")
    T->>TS: activity fraud_check (collusion/velocity via Neo4j GDS signals)
    T->>LG: activity hold_escrow (campaign budget → escrow, idempotency key)
    Note over T: durable timer — 7 day dispute window (signal cancels)
    T->>LG: activity settle_commission (escrow → referrer payable)
    LG->>K: ledger.entry.posted.v1
    T->>RW: activity award_referrer_xp
    RW->>K: rewards.xp.awarded.v1
    T->>RS: activity mark_referral_settled → outbox referral.commission.settled.v1
    K-->>TS: settled event → referral factor s₂ ↑ → trust.score.updated.v1
    K-->>Ref: push "₹45,000 deal settled — commission ₹2,250 credited"
```

(Compensation path — dispute or ledger failure → `release_escrow` — detailed in `03-backend-architecture.md` §5.2.)

### 6.5 Intro request → accept → meeting scheduled

```mermaid
sequenceDiagram
    autonumber
    participant A as Requester (Dev)
    participant NS as networking-service
    participant C as Connector (Rohan)
    participant B as Target (Anita)
    participant K as Kafka
    participant RL as relationship-service
    participant TS as trust-service

    A->>NS: POST /v1/intro-requests {target, connector, context, message}
    NS->>NS: validate: band ≥ bronze, connector↔target relationship exists
    NS->>NS: outbox networking.intro.requested.v1
    NS-->>A: 201 {status: pending_connector, expiresAt +7d}
    K-->>C: push "Dev asked you to introduce him to Anita"
    C->>NS: POST /v1/intro-requests/{id}/accept {note}
    NS->>NS: outbox networking.intro.accepted.v1
    K-->>B: push + in-app: double-opt-in prompt for Anita
    B->>NS: POST /v1/intro-requests/{id}/accept   (target consent — no non-consensual intros)
    NS-->>A: status: connected — shared thread opened
    A->>NS: POST /v1/intro-requests/{id}/meetings {scheduledAt}
    NS->>NS: outbox networking.meeting.scheduled.v1
    K-->>RL: record interaction on A↔B (new), A↔C, C↔B (reciprocity signals)
    Note over TS: meeting held & confirmed later → promise-keeping factor for all three;<br/>connector earns vouch-adjacent trust credit
```

### 6.6 WhatsApp campaign send

```mermaid
sequenceDiagram
    autonumber
    participant Org as Org dashboard
    participant CP as campaign-service
    participant T as Temporal (campaign-send ns)
    participant AI as ai-gateway
    participant CH as channel-service
    participant WA as WhatsApp Cloud API
    participant K as Kafka

    Note over Org,WA: prerequisite: template approved
    Org->>CP: POST /v1/channels/whatsapp/templates (via channel-service)
    CH->>WA: create message template
    WA-->>CH: webhook: template APPROVED
    Org->>CP: POST /v1/campaigns/{id}/send {sendAt}
    CP->>CP: freeze audience snapshot; outbox campaign.campaign.scheduled.v1
    CP->>T: start CampaignSendWorkflow(id=f"send-{campaignId}")
    CP-->>Org: 202 {runId}
    Note over T: durable timer until sendAt (recipient-local windows)
    loop batches of 100 recipients
        T->>AI: activity: personalize batch ({{ai.festivalLine}} per recipient, guardrails)
        T->>CH: activity: send batch (per-number rate + quality-tier budget)
        CH->>WA: POST /messages (template + params) per recipient
        WA-->>CH: message ids
        CH->>K: campaign.message.sent.v1 (per recipient)
    end
    WA-->>CH: webhooks: delivered / read / replied / failed (signature verified)
    CH->>K: campaign.message.delivered.v1 / read.v1 / replied.v1 / failed.v1
    K-->>CP: analytics projection updates funnel
    Note over CH: quality rating drops to MEDIUM → CH throttles sends,<br/>signals workflow to slow batch cadence (protect the WABA number)
    Org->>CP: GET /v1/campaigns/{id}/analytics → {sent 47, delivered 46, read 39, replied 12}
```

### 6.7 Trust score update (event-driven pipeline)

```mermaid
sequenceDiagram
    autonumber
    participant K as Kafka
    participant TC as trust-service consumer
    participant PG as trust PG (factor ledger)
    participant N4 as Neo4j (+GDS)
    participant R as Redis
    participant NT as notification-service

    K-->>TC: referral.commission.settled.v1 (any weighted event: deals, vouches, events, knowledge…)
    TC->>TC: dedup event_id (processed_events, same tx)
    TC->>PG: append trust_factor_ledger row {userId, component, rawValue, eventRef}
    TC->>TC: incremental recompute: component sᵢ (time-decay half-life 180d, Wilson smoothing)
    TC->>N4: update vouch/referral edges
    alt collusion check triggered (velocity threshold)
        TC->>N4: GDS: dense reciprocal-cluster score
        N4-->>TC: damping coefficient
        opt anomaly
            TC->>K: trust.anomaly.detected.v1 (component s₉ subtracts)
        end
    end
    TC->>PG: upsert score snapshot {score: 712, band: gold, version++}
    TC->>R: SET trust:band:usr_x (60s TTL cache for gRPC GetBand)
    TC->>K: trust.score.updated.v1 {old, new, topFactor}
    K-->>NT: band change only → push "You reached Gold"
    Note over TC,PG: nightly Temporal reconciliation workflow recomputes all components<br/>from the ledger and diffs vs streaming state (drift alert > 1 point)
```

### 6.8 Offline mobile write sync

```mermaid
sequenceDiagram
    autonumber
    participant UI as Flutter UI
    participant D as Drift (SQLite) + op queue
    participant SY as sync engine (client)
    participant GW as api-gateway
    participant S as owning services

    Note over UI,D: user is offline (train to Pune)
    UI->>D: log interaction; edit contact; draft referral
    D->>D: append ops {opId: uuid7, entity, baseVersion, payload} — optimistic UI updates
    Note over SY: connectivity restored
    SY->>GW: POST /v1/sync/batch [ops] — each op carries Idempotency-Key = opId
    GW->>S: fan out as ordinary REST calls (BFF hosts the batch endpoint)
    alt op accepted
        S-->>SY: 2xx + new version → D marks op applied
    else version conflict (412 stale-version)
        S-->>SY: 412 + server state
        SY->>SY: merge policy per entity: notes = field-merge;<br/>interactions = append (no conflict possible);<br/>referral submit = server wins, surface to user
        SY->>UI: conflict card only when policy = manual
    else duplicate (idempotency replay)
        S-->>SY: replayed 2xx (Idempotency-Replayed) → safe after crash mid-sync
    end
    SY->>GW: GraphQL delta query {entities changed since lastSyncCursor}
    GW-->>SY: changed rows → D upserts → UI reactively updates (Riverpod)
```

Design choices: op-based queue (not row diffing) so intent survives; `opId` doubles as the idempotency key making retry-after-crash safe; server never merges silently on `manual` entities. Deletion tombstones retained 30 d for lagging devices.

### 6.9 AI copilot message generation (via ai-gateway with guardrails)

```mermaid
sequenceDiagram
    autonumber
    participant App as Flutter app
    participant AR as agent-runtime (Relationship agent)
    participant AI as ai-gateway
    participant Q as Qdrant
    participant LLM as Anthropic (claude-sonnet-5)
    participant K as Kafka

    App->>AR: POST /v1/copilot/messages {intent, context{contactId, meetingId}, tone}
    AR->>AR: authz: actor owns contactId (Cerbos); load agent memory
    AR->>Q: RAG: retrieve meeting summary + relationship timeline embeddings
    AR->>AI: generate {promptTemplateId: "followup.v7", variables, grounding docs}
    AI->>AI: input guardrails: PII minimization (pseudonymize before prompt),<br/>injection scan on retrieved docs, budget check (plan tokens)
    AI->>LLM: messages API (prompt from registry v7, temperature 0.7)
    LLM-->>AI: 2 variants
    AI->>AI: output guardrails: impersonation check, claims-vs-grounding check,<br/>channel policy (WhatsApp: no link shorteners), toxicity
    alt guardrail failure
        AI-->>AR: 422 guardrail-blocked {reasonCode}
        AR-->>App: problem+json (never the raw model output)
    else pass
        AI->>K: ai.generation.completed.v1 {generationId, model, tokens, costMinor, latencyMs}
        AI-->>AR: variants + usage
        AR-->>App: 200 {variants, grounding, usage}
    end
    App->>AR: POST /v1/copilot/generations/{id}/feedback {rating: up, finalText}
    AR->>K: ai.feedback.recorded.v1 → eval pipeline (edit distance = implicit quality signal)
```

---

## 7. OpenAPI Governance

### 7.1 Spec-first workflow

The spec **is** the contract; code conforms to it (never generated *from* code — FastAPI's auto-spec is disabled, `03-backend-architecture.md` §2.7 `openapi_url=None`):

1. Endpoint change starts as a PR to `contracts/openapi/<service>.v1.yaml` — reviewed by the service team + an API-guild reviewer (CODEOWNERS).
2. CI (`contracts.yml`): Spectral lint (§7.2) + `oasdiff` breaking-change gate (breaking on `/v1/` = build failure, no exceptions without a version bump).
3. Merged spec publishes to the internal API portal and triggers SDK regeneration (§7.3).
4. Service CI runs **schemathesis** against the running service with the merged spec — implementation drift fails the service build, not the contract build.

### 7.2 Spectral ruleset (`contracts/.spectral.yaml`, excerpt)

```yaml
extends: ["spectral:oas"]
rules:
  trustos-problem-details:
    description: Every 4xx/5xx response must be application/problem+json
    given: $.paths[*][*].responses[?(@property >= '400')].content
    severity: error
    then: { field: application/problem+json, function: truthy }
  trustos-idempotency-key:
    description: POST operations must declare the Idempotency-Key header parameter
    given: $.paths[*].post.parameters
    severity: error
    then: { function: schema, functionOptions: { schema: { contains: { properties: { name: { const: Idempotency-Key } } } } } }
  trustos-cursor-pagination:
    description: List responses must use data + pageInfo envelope (no offset params)
    given: $.paths[*].get.parameters[?(@.name == 'offset')]
    severity: error
    then: { function: falsy }
  trustos-rate-tier:
    description: Every operation declares x-trustos-rate-tier
    given: $.paths[*][*]
    severity: error
    then: { field: x-trustos-rate-tier, function: enumeration,
            functionOptions: { values: [auth, read, write, bulk, ai] } }
  trustos-camel-case-props:
    given: $..properties[*]~
    severity: error
    then: { function: casing, functionOptions: { type: camel } }
  trustos-operation-id-format:
    given: $.paths[*][*].operationId
    severity: error
    then: { function: casing, functionOptions: { type: camel } }   # e.g. submitReferral → SDK method names
```

### 7.3 SDK generation (Dart for Flutter)

- Pipeline: merged specs → bundled gateway spec (`redocly bundle`) → **openapi-generator `dart-dio`** with a maintained custom template set → `trustos_api` package published to the internal pub registry, versioned by spec content hash + date (`1.34.0+2026.07.07`).
- Template customizations (this is where SDK quality lives): prefixed-ID types as value classes; `Money` as a real class with no double anywhere; **unknown enum values decode to `.unknown`** instead of throwing (forward compatibility, §1.2); generated `Idempotency-Key` injection + retry interceptor honoring `Retry-After`/`RateLimit`; DPoP signing interceptor hooking the platform keystore; Problem Details decoded into a sealed `TrustOsProblem` class hierarchy for exhaustive `switch` handling in Riverpod controllers.
- The BFF GraphQL side uses `graphql_codegen` against `contracts/graphql/bff-mobile.graphql` + the persisted-query manifest baked at app build.
- Same pipeline emits a TypeScript SDK (org dashboard web) and keeps Postman/Insomnia collections current — one source, all artifacts.

### 7.4 Deprecation policy

1. Mark in spec: `deprecated: true` + `x-trustos-sunset: "2027-07-01"` + successor link. Spectral requires both fields together.
2. Runtime headers from the gateway on every deprecated call: `Deprecation: true`, `Sunset: Wed, 01 Jul 2027 00:00:00 GMT`, `Link: </v2/...>; rel="successor-version"`.
3. Gateway metrics per (endpoint, client version, org) → dashboard of remaining consumers; outreach at 90/30/7 days for org integrations.
4. Minimum windows: 12 months for public endpoints, 6 months for BFF persisted queries (app-release cadence governs), 3 months for internal gRPC (buf breaking + consumer-driven contract tests catch stragglers).
5. After sunset: `410 Gone` with a problem body pointing to the successor — never silent removal, never behavior change under the same path.

---
*End of 04 — API Design. Implementation patterns for every endpoint here: `03-backend-architecture.md`. Trust math referenced in §4.3/§6.7: `06-algorithms.md`.*
