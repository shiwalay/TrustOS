# TrustOS — First Principles of BNI, Rebuilt AI-Native: The Opportunity Network Strategy

> **Thesis:** BNI proved that *structured, measured, reciprocal giving inside a trusted small group* reliably converts relationships into revenue. TrustOS extracts those mechanics from their 1985-era container (weekly breakfast meetings, paper slips, one chapter president) and rebuilds them as software: a trust graph instead of human memory, continuous opportunity detection instead of weekly referral rounds, a verified outcome ledger instead of thank-you slips — and, decisively, **an Opportunity Network instead of a referral network**: referrals are one of ten opportunity types the same trust pipeline can detect, route, and settle.

Conforms to [`_shared-context.md`](_shared-context.md) (binding). Extends the canonical event taxonomy per its extension clause (§7 below, marked ⊕). Siblings: PRD [`01-prd.md`](01-prd.md) · algorithms [`06-algorithms.md`](06-algorithms.md) · AI [`07-ai-architecture.md`](07-ai-architecture.md) · roadmap [`14-roadmap.md`](14-roadmap.md).

---

## 1. Executive Summary

BNI generates ~$25B/yr in member-reported business across ~11,000 chapters with almost no technology, which makes it the most important *proof of demand* in this category: professionals will pay ~$1,500/yr **and attend 50 meetings a year** for structured referral exchange. The product insight is that everything members pay for is an *outcome* (trusted referrals, accountability, belonging) delivered through *mechanisms* that are artifacts of their era: geography-locked chapters, one-category-per-seat scarcity, attendance discipline, human bookkeeping.

TrustOS keeps the outcomes and replaces the mechanisms:

- **Trust that was performed weekly** becomes trust that is *measured continuously* (Digital Trust Index, factor-ledger-backed — [`06-algorithms.md`](06-algorithms.md) §1).
- **Referral rounds limited by human memory** become *continuous opportunity detection* over a relationship graph + embeddings (networking-service).
- **Paper slips and self-reported "closed business"** become a *verified outcome ledger* (deal-service + double-entry ledger-service — already implemented for referrals in `platform/`).
- **The chapter president's clipboard** becomes an *AI Community Manager* (Community Agent) that does the operations while humans keep the ceremony.
- **The referral network becomes an Opportunity Network** — the same pipeline (Person → Relationship → Trust → Detection → Recommendation → Verified Outcome → Trust Increase → Network Growth) settles referrals, partnerships, hires, investments, mentorships, speaking slots, collaborations, consulting, vendor matches, and community invites.

The result is not "digital BNI." It is the category BNI would have built if it were founded in 2026: an operating system for trusted business relationships whose every verified outcome makes the graph — and therefore every future recommendation — better.

## 2. Core Philosophy

1. **Trust is capital.** It accrues, compounds, depreciates, and can be spent. TrustOS makes it measurable (DTI), explainable (factor ledger), and productive (opportunity routing) — without ever making it purchasable.
2. **Givers Gain, instrumented.** BNI's creed works because giving is *tracked and reciprocated within a bounded group*. TrustOS instruments giving platform-wide: every intro, referral, answer, and mentorship hour is a ledger fact that feeds trust and surfaces reciprocity imbalances before they curdle.
3. **Outcomes over activity.** Attendance, likes, and message counts are theater. Only two-party-verified outcomes move scores, leaderboards, and money. (PRD north star: Weekly Trusted Business Interactions.)
4. **AI does the labor; humans do the trust.** AI remembers, detects, drafts, schedules, and verifies. Humans meet, vouch, decide, and celebrate. Any design where AI *performs* the relationship is rejected.
5. **The network must be worth joining at n = 1.** BNI is worthless alone; TrustOS must not be (single-player relationship intelligence first — PRD §2).

## 3. Product Principles

| # | Principle | Concrete rule |
|---|---|---|
| P1 | Opportunity Network, not referral network | Every module that handles referrals must handle all ten opportunity types through one lifecycle (§7) |
| P2 | Verified or it didn't happen | No score, leaderboard, or payout moves on self-report; two-party confirmation or ledger evidence required |
| P3 | Explanation-first trust | Every score movement is one tap from its cause; appeals exist (06 §1) |
| P4 | Async-first, meeting-optional | Meetings are a *tool* the platform schedules when they're the highest-value next action — never a tax |
| P5 | Communities own their culture | AI runs operations; elected humans set norms; the platform never overrides a community's governance |
| P6 | Reciprocity is visible | Give/receive balance is surfaced privately to the member before it's ever visible to anyone else |
| P7 | No pay-to-trust | Money buys tools and reach ceilings only; never score, rank, or vouches (BR catalog, PRD §7) |

## 4. BNI, Decomposed to Atoms

### 4.1 The full matrix

For every atomic system: **why it exists** (the human problem), **its weakness at scale**, and the **TrustOS replacement**.

| BNI atomic system | Why it exists (first principle) | Structural weakness | TrustOS replacement |
|---|---|---|---|
| Membership application & vetting | Screen for reliability before extending group trust | Subjective, chapter-variance, slow | Verification ladder T0–T4 (identity-service) + DTI cold-start priors |
| One seat per category | Kill intra-group competition → safe to refer | Artificial scarcity caps revenue & fit; rigid taxonomy | Dynamic expertise graph (:HAS_SKILL + embeddings); exclusivity becomes *per-opportunity routing priority*, not a locked seat |
| Weekly meeting | Repetition → familiarity → trust (mere-exposure); forcing function | 100+ hrs/yr; geography-locked; timezone-hostile | Daily AI networking moments: 5-min curated actions (one intro to accept, one contact going quiet, one ask to answer) |
| 60-second pitch | Teach the group how to refer you | Memory decays by lunch | Business DNA: living, versioned "how to refer me" profile the AI injects into every relevant moment |
| One-to-one meetings | Structured vulnerability → deep ties | Scheduling friction; unprepared participants | Relationship Agent preps both sides (shared context brief, suggested agenda), books it, extracts commitments after |
| Referral slips | Make giving *countable* | Paper → self-report → no attribution | Verified referral ledger (**built**: referral-service state machine + outbox events) |
| "Thank You for Closed Business" | Anchor trust in verified money | Self-reported, gameable, celebrated monthly | deal-service + ledger-service settlement; celebration fires on `referral.commission.settled.v1` (the app's only full-screen moment — 10-ux §7) |
| Attendance & absence policy | Reliability signaling; commitment device | Measures presence, not contribution | Trust Activity Score: contribution-weighted consistency component of DTI (kept meetings, answered asks, settled outcomes) |
| Visitor days | Controlled top-of-funnel with social proof | Awkward; conversion depends on chapter charisma | Guest mode: prospective members see the community's *verified outcome feed* and their own simulated fit before joining |
| Chapter president / LT | Coordination, norm enforcement, energy | Leader lottery — chapter quality variance is BNI's #1 churn driver | AI Community Manager (Community Agent: agenda, follow-ups, health alerts, moderation triage) + elected human host for ceremony & norms |
| Education (MSP, podcasts) | Networking is a learnable skill | Generic, not situational | Knowledge Agent: coaching injected at the moment of action ("this intro message is cold; here's why") |
| Category/industry taxonomy | Referrability requires legible identity | Static, gameable, granularity wars | Expertise graph inferred from verified work + endorsements, re-clustered continuously (Neo4j GDS) |
| Regional directors / franchise | Scale through owned operators | Cost, inconsistency, incentive misalignment | Community templates + Community Health Index + platform ops; franchise economics → community revenue share (PRD §7) |
| Awards & recognition | Status rewards for giving | Monthly, local, forgettable | Leaderboards on verified value (§11) + badges with provenance (rewards-service) |
| Renewal / dues | Commitment device + revenue | Opaque ROI at renewal time | ROI receipt: "TrustOS routed you ₹4.2L verified business this year" — renewal against evidence, not memory |

### 4.2 Deep dives — the six load-bearing systems

**(a) Weekly meeting → Daily AI Networking.** The meeting bundles four jobs: visibility (I exist), education (how to refer me), liquidity (referral exchange), and belonging. TrustOS unbundles: visibility → Business DNA surfaced contextually; education → AI coach; liquidity → continuous opportunity detection; belonging → community events *chosen* for connection, not obligation. The forcing-function job — "show up or decay" — is preserved honestly: trust consistency decays without contribution (H=180d half-life, 06 §1). What we deliberately keep human: the community still meets (monthly/quarterly, online or in person), because ceremony builds bonds software can't. What we refuse to keep: attendance as the *metric*.

**(b) Referral slip → Opportunity pipeline.** BNI's slip is a paper database row with no schema, no attribution, and no settlement. TrustOS's referral lifecycle (submitted → qualified → converted → settled, escrow + double-entry commission) is already running code. §7 generalizes it to all opportunity types.

**(c) One seat per category → routing priority.** The scarcity rule exists to make giving *safe* (my referral won't feed my competitor). The AI-native equivalent: opportunity routing is *trust-and-fit ranked*, and within a community the member with the strongest verified track record in an expertise cluster gets first-look on matching opportunities (a earned, decaying priority — not a purchased seat). Safety is preserved; the artificial revenue ceiling and category-boundary lawyering are not.

**(d) Accountability → Trust Activity.** BNI enforces with attendance ledgers and polite expulsion. TrustOS enforces with consequences that scale: contribution decay lowers DTI band → lowers routing priority → fewer opportunities. No meetings with a disciplinarian; the physics of the system do the work, with explanation-first UX so it never feels like a black box.

**(e) Chapter president → AI Community Manager + human host.** Everything operational (agendas, reminders, tracking, health monitoring, dispute triage, onboarding) → Community Agent (07 §3, Cerbos-scoped). Everything symbolic (welcoming, celebrating, norm-setting, conflict resolution) → elected human host. This directly attacks BNI's biggest quality variable — the leader lottery — while keeping the human center.

**(f) Visitor experience → evidence-based trial.** BNI converts visitors with room energy. TrustOS converts with receipts: a guest sees the community's verified outcome feed (₹X settled this quarter, N intros → M meetings), plus an AI-simulated "your fit here" preview from their Business DNA. Charisma-independent, globally consistent.

## 5. BNI vs TrustOS

| Dimension | BNI | TrustOS |
|---|---|---|
| Unit of trust | Membership + attendance | Digital Trust Index (0–1000, factor-ledger-backed, contestable) |
| Referral discovery | Human memory, weekly, ~40 people | Graph + embeddings, continuous, entire trusted network |
| Opportunity types | Referrals | Ten types, one pipeline (§7) |
| Verification | Self-reported slips | Two-party confirmation + escrowed settlement |
| Geography | Chapter = a city breakfast | Communities = interest/industry/city, global, async-first |
| Cost to member | ~$1,500/yr + 100+ hours | Freemium; Pro ≈ ₹499/mo India (PRD §7); hours replaced by minutes |
| Leadership | Volunteer lottery | AI operations + elected human ceremony |
| Data compounding | None (resets every meeting) | Every outcome improves detection for everyone (AI Learning Loop) |
| Scale ceiling | ~40/chapter (Dunbar + format) | Communities of 50–5,000; graph-scale routing across communities |
| Trust portability | Dies at the chapter door | Portable credential (Delta-4 stage 5) |

## 6. Feature Mapping — "Instead of X, build Y"

| Instead of | TrustOS builds | Owning service |
|---|---|---|
| Weekly meeting | Daily networking moments (3-action queue) | networking-service + notification-service |
| One referral per week | Continuous opportunity discovery | networking-service (opportunity engine) |
| Human memory | Relationship graph + timeline | relationship-service / Neo4j |
| Attendance | Trust Activity Score | trust-service (consistency component) |
| Referral slips | Verified referral/opportunity ledger | referral-service + deal-service + ledger-service |
| Chapter president | AI Community Manager + human host | agent-runtime (Community Agent) |
| Business categories | Dynamic AI expertise graph | profile-service + Neo4j GDS |
| 60-second pitch | Business DNA (living referral profile) | profile-service + Qdrant |
| One-to-one meetings | AI-prepped intros with shared briefs | agent-runtime (Networking + Relationship Agents) |
| Member education | Moment-of-action coaching | knowledge-service + Knowledge Agent |
| Regional franchise | Community templates + Health Index | community-service |
| Renewal by habit | Renewal by ROI receipt | analytics-service |

## 7. The Opportunity Network (strategic centerpiece)

**From referral network → opportunity network.** BNI monetizes one edge type. A trusted relationship can carry many:

```
Person → Relationship → Trust → Opportunity Detection
              ↓
   ┌───────────────────────────────┐
   │ Referral        Partnership   │
   │ Hiring          Investment    │
   │ Mentorship      Speaking      │
   │ Collaboration   Consulting    │
   │ Vendor match    Community invite │
   └───────────────────────────────┘
              ↓
   AI Recommendation (both-sides-benefit check)
              ↓
   Verified Outcome  →  Trust Increase  →  Network Growth ─┐
              ▲                                            │
              └────────────── (compounds) ─────────────────┘
```

**One lifecycle, ten types.** Generalize the referral state machine (03 §2) into an `Opportunity` model:

`detected → suggested → accepted_by_both → in_progress → outcome_verified → value_settled | declined | expired`

Type-specific parameters, same skeleton:

| Type | Detection signals (examples) | Outcome verification | Value event |
|---|---|---|---|
| Referral | Need expressed + provider trusted + campaign live | Deal won + invoice paid | Commission settled (escrow) |
| Partnership | Complementary offerings, shared clients, co-bid patterns | Signed agreement (both confirm) | Trust + optional platform fee on marketplace-transacted volume |
| Hiring | Role posted + candidate skills/tenure signals | Offer accepted (both confirm) | Flat success fee (compliant with local recruitment rules) |
| Investment | Raise declared + investor thesis match | Both confirm intro→term-sheet stage | **No success fee — trust only** (broker-dealer/SEBI merchant-banking licensing risk; unlicensed transaction-based comp is a company-ending mistake. Monetize tooling, never the transaction) |
| Mentorship | Skill gap ↔ verified expertise + declared willingness | Sessions held (both confirm) | Trust + badges; optional paid mentorship via marketplace |
| Speaking | Event needs topic ↔ knowledge contributions | Talk delivered (organizer confirms) | Trust + community XP |
| Collaboration | Overlapping project needs | Deliverable shipped (both confirm) | Trust |
| Consulting | Problem statement ↔ expertise cluster | Engagement invoiced | Marketplace take-rate |
| Vendor match | Procurement ask ↔ supplier record | PO/first invoice | Marketplace take-rate |
| Community invite | Fit score ↔ community thesis | Joined + 30-day activation | Community growth credit |

**Architectural impact (marked ⊕ extensions to the canonical registry/taxonomy):**
- networking-service grows an **opportunity engine**: detection pipelines per type over Neo4j features + Qdrant similarity + declared intents ("raising," "hiring," "need a CA"). Candidate gen → rank (objective: *verified outcomes per 100 suggestions*, not accepts) → both-sides-benefit + reciprocity checks (06 §4).
- deal-service generalizes to the **Outcome Ledger** for all types (referral remains the exemplar implementation).
- ⊕ Events: `networking.opportunity.detected.v1`, `networking.opportunity.accepted.v1`, `deal.outcome.verified.v1` — extending, not replacing, the referral events.
- trust-service: the DTI "referral performance" component (weight 0.20) generalizes to **opportunity performance** — same Wilson smoothing and decay, per-type sub-scores, economically-verified types weighted highest. Weights remain governed + shadow-tested per 06 §1.
- **Declared intents** become a first-class profile object ("what I'm looking for / offering this quarter") — the highest-precision detection signal and a privacy-clean one.

**Why this wins:** referral-only liquidity is the hardest cold-start in the category (PRD risk C1). Six of the ten types (mentorship, collaboration, speaking, community invites, partnership, hiring-lite) need **no money movement** — they generate verified outcomes and trust *before* the referral marketplace has liquidity, then hand the warmed graph to the monetized types. The Opportunity Network is simultaneously the cold-start solution and the moat.

### 7.1 Invitation-only membership (⊕ launch mechanic)

TrustOS launches **invitation-only**: joining requires a member's code (`TRUST-XXXX`), and **an invitation is a vouch** — not marketing.

- **Mechanics:** every member holds a scarce allotment (5, replenished by verified contribution, never purchasable). Redeeming a code creates the invitee's first `:VOUCHES_FOR` edge in Neo4j and seeds their DTI cold-start prior from the inviter's band (damped). Codes are single-use, expiring, issued by identity-service; the invite → activation → first-verified-outcome funnel is tracked like any opportunity type (community-invite).
- **Skin in the game:** an invitee's early conduct reflects back — fraud or spam by the invitee damps the *inviter's* vouch weight (same personalized-PageRank damping as all vouches, 06 §1). This makes members curate, which is the entire quality bet of BNI's application committee, decentralized.
- **Growth without spam:** the member-facing surface is a pre-written, personal invite message carrying the code ("I'm using one of my five invitations on you") — sent person-to-person through the member's own channels. Scarcity + provenance replaces paid acquisition at launch and is coherent with the premium brand ("chosen, not acquired").
- **The door stays ajar:** no invitation → visible waitlist; nearby members with matching-industry fit are shown waitlist requests as community-invite opportunities. Uninvited demand becomes inventory, not a dead end.
- **Exit criteria:** invitation-only is a *phase*, not a religion — it lifts early trust density and brand, but caps growth. Relax per-city once liquidity gates (PRD §9) are met, keeping vouch-seeded onboarding as the default path even when codes are no longer required.

### 7.2 The Ask & Offer board (⊕ the opportunity funnel's mouth)

Every opportunity in §7 starts as a signal. The **Ask & Offer board** is where members declare those signals in plain language — and a declared intent is the single highest-precision input the opportunity engine has.

- **Two post types.** An **Ask** ("I need a warm intro to a CFO", "a reliable CA", "500 units of eco packaging") and an **Offer** ("5,000 sq ft of spare warehousing", "mentoring two D2C founders", "hiring a senior engineer"). An Ask matched to an Offer *is* an Opportunity — it enters the existing lifecycle (§7: `detected → suggested → accepted_by_both → …`). The board is the human-authored top of the funnel; the engine does the routing.
- **Visible to anyone, surfaced by relevance — not a firehose.** Posts are public, but each member's feed is trust-and-relevance ranked (embedding fit to their expertise/needs + graph proximity + poster's trust band + declared intents + freshness), community/city first. "Discoverable by anyone" ≠ "a global chronological dump."
- **Three ways to act, and the third is the point:**
  1. **Respond** ("I can help" / "I want this") → opens a double-opt-in thread; on a verified outcome it settles and scores like any opportunity.
  2. **Relay / push further** → forward a post to a contact who fits. This turns every member into a *router of opportunities*: "I don't have this, but I know who does." The relayer becomes the **connector**, and a relay chain that ends in a verified fulfilment credits the connector (relationship/community-contribution component of the DTI). Multi-hop relays are traceable as a `:RELAYED` edge in Neo4j, so connector chains are auditable and creditable.
  3. **Boost/endorse** → a light amplification/vouch signal that lifts a post in trusted feeds.
- **Where it owns:** an Ask/Offer is a lightweight, human-authored opportunity seed in **networking-service** (front door to the opportunity engine); community-scoped boards surface via community-service; the "Asks & offers" segment of the Daily Briefing (18 §1.3) is this same board, pre-collected overnight and ordered by match strength.
- **Anti-spam & integrity:** posting is tier-gated (T1+) and frequency-governed (no flooding the board); low-quality/spam posts down-rank and route to moderation (18 §2); only *verified two-party outcomes* score, so gaming the board earns nothing.
- ⊕ Events: `board.post.created.v1`, `board.post.responded.v1`, `board.post.relayed.v1`, `board.post.matched.v1`, `board.post.fulfilled.v1`, `board.post.expired.v1`. ⊕ Data: `ask_offer_posts`, `post_responses`, `post_relays` (the connector graph), `post_matches`.

This is the async, continuous version of the BNI meeting's "asks & offers" round — and the relay mechanic is the trust graph doing what it exists to do: warm-route an opportunity to the person who can actually close it.

## 8. System Architecture & AI Enhancements (delta view)

No new services; four grow (all within [`02-system-architecture.md`](02-system-architecture.md) patterns):

| Service | Delta |
|---|---|
| networking-service | Opportunity engine: per-type detectors (Kafka consumers over relationship/deal/community events + intent changes), ranking model per 06 §4, routing-priority computation (§4.2c) |
| deal-service | Outcome Ledger: `opportunity_outcomes` (typed, both-party confirmation FSM); invoices path unchanged |
| agent-runtime | Networking Agent gains opportunity tools (typed, read-mostly; settlement stays human-confirmed). Community Agent gains chapter-ops toolkit: agenda gen, health alerts, silent-member nudges, dispute triage — all Cerbos-scoped, suggest-only for anything member-facing (07 §3 guardrails) |
| analytics-service | Community Health Index, Referral/Opportunity Velocity, RLV materialized views (ClickHouse) |

New derived intelligence (named modules → homes): **Business DNA** (profile-service + Qdrant embedding of verified work, not self-description), **Professional Reputation** (DTI + per-type opportunity sub-scores), **Business Health Score** (deal-service: pipeline velocity, revenue concentration), **Networking Score** (intro acceptance × meeting-held rate), **Community Health Index** (§10), **Referral Velocity** (time-to-stage distributions), **Relationship Lifetime Value** (predictive ML per 07 §6: expected verified value routed through this relationship over 24 months — the number that makes "reconnect with Rohan" a business decision, not sentiment).

## 9. User Journey (the daily loop that replaces the weekly meeting)

**Morning (2 min):** push digest — *one* intro to accept (with why-this-match + shared-context brief), *one* relationship at risk (RLV-ranked), *one* community ask you can answer. Acting on any is a trust-relevant contribution.
**Midday (contextual):** opportunity engine surfaces a detected match: "Priya's firm is hiring a CFO; your contact Anil fits and is open — introduce?" One tap sends an AI-drafted, human-edited double-opt-in intro.
**Evening (ambient):** meeting summarizer extracted two commitments from your 4pm call into follow-up automations (08 §2); your community leaderboard ticked because yesterday's vendor match hit first-invoice.
**Weekly:** community digest — verified value settled, new members with fit scores, one challenge. **Monthly:** the ceremony a community chooses (demo day, mastermind) — scheduled and prepped by the Community Agent, hosted by humans.
Journey-level principle: *the platform spends your attention like your money — three actions beat thirty notifications* (frequency governor, 08 §4).

## 10. Community Framework (AI-powered micro business communities)

Composition per community (all existing modules — community-service + agents): members (verification-gated per community policy), events, knowledge hub, marketplace shelf, opportunity board (supersedes "referral board"), leaderboards, challenges ("10 verified intros this month" — community vs community), mentoring pairs (Opportunity type), **AI Moderator** (triage → human decides), **AI Matchmaker** (member↔member per opportunity type), **Community Trust Score** (aggregate, gates community-vs-community features), **Community revenue** (share of platform fees on intra-community settled value — replaces franchise economics, aligns host incentives with member outcomes), analytics.

**Community Health Index (CHI)** — the operating metric replacing "is the president any good": weighted blend of verified-outcome velocity per member, reciprocity balance (Gini on give/receive), new-member 30-day activation, retention, ask-response rate, event follow-through. Published to hosts with prescriptions ("asks are dying unanswered — run an experts hour"), used by platform ops for template intervention, and — honestly — a churn early-warning system BNI never had.

## 11. Leaderboard, Gamification, Trust (deltas only — canon lives in 06)

- Leaderboards reward **value creation only**: Business Generated (ledger-verified), Trust growth, Opportunities settled (per type), Community Impact, Knowledge Contribution, Mentorship. Activity counts appear nowhere. Anti-gaming: only settled/two-party-verified events score; collusion rings damped via GDS; percentile bands not raw ranks; decay leagues (06 §5–6).
- Gamification remains firewalled from trust (gamification → community-contribution component only, capped at 10%) and from money (closed-loop coins). The *new* gamified surface: **community challenges** on verified-outcome metrics — competition between communities, cooperation within them (BNI's inter-chapter rivalry, pointed at value instead of attendance).
- Trust framework unchanged (DTI canon) with one generalization: referral component → opportunity performance (§7), and one addition: **cross-community vouches** carry personalized-PageRank-damped weight so trust can travel without being farmable.

## 12. Flywheels

| Flywheel | Loop | Why it compounds |
|---|---|---|
| Relationship | import → insight → act on nudge → interaction logged → better insight | Timeline density ↑ → relationship-at-risk detection precision ↑ → more relationships saved |
| Trust | verified outcome → DTI ↑ → better routing priority → more opportunities → more outcomes | Trust converts directly into deal flow; deal flow is the retention hook |
| Opportunity | more members+intents → more detected matches → more settled outcomes → outcome data trains ranker → higher match precision | The AI Learning Loop rides this: every settlement is a labeled example nobody else has |
| Knowledge | ask → answer → RAG corpus ↑ → agent answers ↑ → more asks arrive | Community-specific corpora are unclonable |
| Community | health ↑ → outcomes ↑ → guest feed more convincing → better members join → health ↑ | CHI makes this measurable and interveneable |
| Marketplace | settled volume → revenue share → hosts recruit → volume ↑ | Aligns the "franchise" layer with member success |
| Leaderboard | visible verified winners → status seekers create value → boards get more credible | Only works because activity can't score — credibility *is* the fuel |
| Business | ROI receipt → renewal + upgrades → funds better AI → more ROI | Ties monetization to the value ledger, not vanity usage |
| AI Learning (meta) | every flywheel emits training signal → detection/ranking/coaching improve → every flywheel spins faster | The compounding of compounding; the reason year-3 TrustOS is unassailable by a fast follower |

## 13. Delta-4 Strategy & Moat

| Stage | What it is | Moat created |
|---|---|---|
| 1. **Product** | Single-player relationship intelligence + campaigns/automations (works at n=1) | Switching cost: your timeline, contacts, automations live here |
| 2. **Platform** | Communities + opportunity board + marketplace; hosts run businesses on TrustOS | Host revenue share = an operator ecosystem with income to defend |
| 3. **Network** | Cross-community trust graph; warm-path routing anywhere in the network | Classic network effects **plus** verified-outcome data no one else possesses |
| 4. **Ecosystem** | APIs: CRMs read relationship intelligence, banks/marketplaces request (consented) trust attestations, developers build community apps | Third-party dependency; TrustOS becomes infrastructure |
| 5. **Operating System** | Portable trust: DTI attestations as a credential for commerce (supplier onboarding, marketplace seller trust, agent-to-agent transactions) | The standards moat — hardest to reach, effectively permanent. Regulatory posture from day one (contestability, DPIA, prohibited-use terms — 11 §8) is the *entry ticket* to this stage, which is why it's built in Phase 0 |

Stage discipline: each stage ships only when the previous stage's flywheel is demonstrably spinning (metrics in §14); premature platform-ing is the standard way to die (PRD Phase-1 kill gate applies).

## 14. Success Metrics

- **North star (kept from PRD):** WTBI — Weekly Trusted Business Interactions (verified, two-party). The Opportunity Network widens what counts (all ten types' verified outcomes) without loosening verification.
- **Dollar north star:** **VBVC — Verified Business Value Created** (ledger-settled value routed through platform-detected opportunities).
- Supporting: opportunity conversion (verified outcomes / 100 recommendations, per type) · verified introductions · relationship growth (active relationships with rising scores/user) · trust growth (median DTI delta of month-6 cohort) · CHI distribution (median + share of communities > threshold) · RLV (mean and concentration) · referral/opportunity velocity (time-to-settle p50).
- Guardrails (unchanged and non-negotiable): trust-integrity (< 0.5% invalidated score points), spam (< 1.5 reports/1k messages), coin-economy issuance ratio, recommendation inbound-burden cap (nobody gets buried in intros — 06 §4).

## 15. Business Model (delta to PRD §7)

Freemium + Pro (PPP-priced) + Org + AI credits unchanged. Opportunity Network adds: marketplace take-rate on consulting/vendor engagements; compliant flat success fees on hiring; **explicitly no transaction fees on investment intros** (licensing); community revenue share as the scaled replacement for franchise fees. Renewal is sold with the ROI receipt — the anti-BNI move: evidence, not obligation.

## 16. Roadmap Integration & Future Vision

Maps onto [`14-roadmap.md`](14-roadmap.md) without re-phasing: **Phase 0–1** ship the pipeline with two types (Referral — built; Community invite) + daily networking moments + Business DNA v1. **Phase 2** adds mentorship/collaboration/speaking (no-money types → liquidity before marketplace) + Community Agent ops + CHI. **Phase 3** adds hiring/consulting/vendor (monetized) + cross-community routing. **Phase 4** opens the ecosystem APIs; portable trust attestations pilot.

**Ten-year vision:** every professional's AI agent negotiates opportunities with other agents *inside* TrustOS's trust and verification rails — because when agents transact on their principals' behalf, the scarce input isn't intelligence, it's **verified trust**. The company that owns the verified-outcome graph of human business relationships owns the settlement layer for that world. That is the operating system BNI accidentally proved the demand for, forty years early.

---

*Challenged assumptions log: investment success fees rejected (licensing); category exclusivity rejected in favor of earned routing priority; meeting-replacement rejected in favor of meeting-optionality; "AI community manager replaces president" softened to AI-ops + human ceremony (norm-setting resists automation); activity leaderboards rejected outright.*
