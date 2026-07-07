# TrustOS — Legal, Terms & Compliance Architecture

> **Status:** framework for counsel review — this is the engineering-and-product-aligned legal architecture, not executed legal advice. Retain qualified counsel in each launch jurisdiction before go-live; several items below (payment aggregation, TDS treatment, AI Act classification) require formal opinions.

India-first (matching the PRD rollout), with EU/US posture staked out early because two of TrustOS's core mechanics — algorithmic reputation and referral commissions — are exactly the things regulators care about. Siblings: [`11-security-architecture.md`](11-security-architecture.md) (technical controls), [`01-prd.md`](01-prd.md) §7 business rules, [`15-opportunity-network-strategy.md`](15-opportunity-network-strategy.md) §7.

---

## 1. The five existential legal risks (read these first)

| # | Risk | Why it could kill the company | Design answer (already in product) + legal answer |
|---|---|---|---|
| 1 | **Trust score treated as social scoring / consumer report** | EU AI Act Art. 5 *prohibits* AI social scoring that causes detrimental treatment in unrelated contexts; in the US, a score used for credit/employment/housing decisions makes you a Consumer Reporting Agency under FCRA — a compliance regime you cannot survive accidentally | DTI is **contextual** (business-networking only), private-by-default, band-only externally, explainable, contestable with human review. Legally: **Prohibited Use clause** — no member or third party may use TrustOS data for credit, lending, employment, housing, insurance, or government eligibility decisions; API terms repeat it; violations = termination + indemnity. Never market the score as "creditworthiness" |
| 2 | **Money movement without licenses** | Holding user funds = payment aggregator/PPI territory (RBI); paying success fees on investment intros = SEBI merchant-banking/broker territory; both are criminal-adjacent if unlicensed | Escrow runs through a **licensed payment-aggregator partner** (nodal/escrow account in the PA's regulated structure — TrustOS never touches the float); **no cash on investment intros ever** (already a product rule); coins are closed-loop, non-purchasable, non-redeemable (outside PPI definition — keep it that way) |
| 3 | **Referral program read as MLM / money circulation** | Prize Chits & Money Circulation Schemes (Banning) Act 1978 + Direct Selling Rules 2021: rewards for *recruitment* or multi-level chains are banned | Commissions attach **only to verified sales outcomes, single level, funded by the buying business** — never to signing up members, never multi-tier. Invitations carry **zero monetary reward** (an invite is a vouch, not an affiliate link) and **selling invitations is a bannable offense** (already in product rules) |
| 4 | **DPDP Act non-compliance on contact upload** | Uploading someone's phone number processes a *non-user's* personal data; DPDP fines reach ₹250 crore | Purpose-limited processing, hashed matching, no profiling of non-members, no messaging non-members (all already product behavior); legally: uploader attests a lawful basis, TrustOS acts with documented purpose limitation, non-member data minimized + crypto-shredded on erasure, and the privacy policy discloses this processing class explicitly |
| 5 | **Messaging = spam liability** | TCCCPR/TRAI (DLT registration, DND), WhatsApp Business policy termination, CAN-SPAM/PECR abroad | Consent classes per recipient (transactional/relationship/marketing — already in PRD BR-041), platform-wide frequency governor, one-tap unsubscribe honored across channels, DLT registration before SMS, WhatsApp template discipline. Terms make members responsible for having consent for contacts they message, with platform enforcement on top |

## 2. Document inventory (what must exist at launch)

**Member-facing (India launch set):**
1. **Terms of Service** (§3)
2. **Privacy Policy** (§4) — DPDP-compliant, English + launch-state languages (DPDP requires availability in 8th-Schedule languages on request)
3. **Referral & Commission Terms** (§5) — the money contract; separate doc so it can version independently
4. **Community Guidelines & Acceptable Use** (§6)
5. **Trust Index Policy** (§7) — how the score works, moves, is contested; the transparency artifact regulators and journalists will read
6. **Grievance & Appeals Policy** — IT Rules 2021 requirement (named Grievance Officer, India-resident; acknowledge in 24h, resolve in 15 days) + DTI appeal path
7. **Refund & Cancellation Policy** — Consumer Protection (E-Commerce) Rules 2020
8. **Cookie/Tracking Notice** — the site's first-party analytics tracker needs disclosure + consent for non-essential

**Business/org-facing:** 9. **Business Terms** (campaign posting: truth-in-offer, funding obligations, dispute windows, prohibited categories); 10. **Data Processing Addendum** (orgs importing CRM data — TrustOS as processor for that data class); 11. **API/Developer Terms** (Delta-4 stage 4 — Prohibited Use travels with every token).

**Internal:** 12. DPIA for the trust score + contact graph (do it now — DPDP "Significant Data Fiduciary" designation is plausible at scale and brings mandatory DPIA/audit/DPO); 13. records-of-processing; 14. incident-response & breach-notification runbook (DPDP: notify Board + affected users — assume "notify"); 15. data-retention schedule (mirrors 05 §10); 16. vendor/sub-processor register.

## 3. Terms of Service — clause architecture

The distinctive clauses (standard boilerplate — eligibility 18+, account security, IP license to operate UGC, termination, force majeure — assumed):

- **The platform's role (the load-bearing clause).** TrustOS is a *technology intermediary*: it facilitates introductions, verifies outcomes, and instructs a licensed payment partner. It is **not** a party to member↔member or member↔business transactions, not an employer/agent of referrers, not a broker, investment adviser, recruitment agency, or credit bureau. Referrers act as **independent persons**, not agents of TrustOS or of the businesses they refer to (kills vicarious-liability and misclassification vectors).
- **Verification ≠ endorsement.** Tiers/bands verify *evidence submitted*, not future conduct. TrustOS does not guarantee any member, referral outcome, or deal.
- **Trust Index terms.** Score is computed per the Trust Index Policy; members get explanation + appeal; TrustOS may adjust for fraud with notice; **no liability for score-derived business outcomes**, and members agree not to represent the score as a government/credit rating.
- **Invitations & vouching.** Invites are personal, non-transferable, **non-salable**; inviter accepts that invitee misconduct affects inviter's vouch weight (consent to the mechanic, in plain language).
- **Money.** All payouts via licensed partner subject to KYC/AML; escrow/dispute windows per Referral Terms; taxes are the member's responsibility; TrustOS may withhold TDS/GST as law requires (§8).
- **Anti-gaming covenant.** Collusion, self-dealing, vouch rings, invite selling, fake outcomes = ledger clawback + termination + liability for damages. (Gives contractual teeth to 06 §1 enforcement.)
- **Disputes.** India: governing law India; **arbitration** (seat: Mumbai or Bengaluru; Arbitration & Conciliation Act 1996; institutional rules e.g. MCIA) *after* mandatory grievance process; carve-outs for injunctive relief and consumer forums (consumer-forum rights can't be fully contracted away in India — don't pretend otherwise). Liability cap: greater of fees paid in 12 months or a fixed floor; no indirect damages; no cap for our own fraud/gross negligence (unenforceable anyway).
- **Modification** with 15-day notice for material changes; continued use = acceptance; money-term changes never retroactive to escrowed amounts.

## 4. Privacy Policy — DPDP-first architecture

- **Roles:** TrustOS = Data Fiduciary for member data; for org-imported CRM data, TrustOS = Processor under DPA. Members uploading contacts act with their own basis; TrustOS's processing of that data is scoped by contract + policy to matching/insight *for the uploader*.
- **Consent UX (already built, keep it legal-true):** itemized, purpose-specific, plain-language consent at collection points (the contact-import screen is the model); no bundled consent; withdrawal as easy as grant (Settings). DPDP consent-manager interop when the ecosystem matures.
- **The contact-data section must say, explicitly:** what's collected on import, that non-members are never profiled or messaged, hashed matching, retention, and the non-member's right to demand erasure through a public channel (an underrated DPDP exposure — give non-members a form, not just members).
- **Automated decision-making & profiling:** describe the DTI, its factors at category level, its effects (routing priority, feature access), the explanation surface, and the human-review appeal. This is GDPR Art. 22 hygiene done *early* so EU expansion doesn't require re-architecture, and it substantively answers DPDP transparency duties.
- **Data principal rights:** access, correction, erasure (crypto-shred — 05 §10), grievance, nomination (DPDP-specific: nominee on death/incapacity — build the Settings surface eventually).
- **Cross-border:** home-region cells (02 §4) mean Indian data stays in India by architecture; policy states transfer posture per jurisdiction (DPDP is blacklist-based; GDPR needs SCCs for any EU→India flows when EU launches).
- **Children:** 18+ only; DPDP's under-18 regime (verifiable parental consent, no tracking) is a reason to hard-gate age at signup, not a feature to build.
- **Breach:** notify Data Protection Board + affected principals promptly; runbook in 11 §9.

## 5. Referral & Commission Terms (the money contract)

- **Definitions locked to the state machine:** submitted/qualified/converted/settled exactly as the product computes them — the contract and the code must never diverge (the code is the source of truth; terms reference in-product definitions).
- **Referred-person consent:** referrals require the prospect's consent within 72h (BR catalog) — both a legal shield (their data) and a spam control; unconsented referrals void.
- **Escrow & release:** commission funds held at the licensed partner on conversion; 14-day no-dispute window; clawback on refund/fraud with ledger transparency; TrustOS fee (take-rate) charged only on settlement.
- **Eligibility to earn:** T4 KYC before payout (not before participation); sanctions/PEP screening at the payment partner; payouts only to same-name bank accounts.
- **Disclosure duty:** referrers must not misrepresent themselves and must disclose a paid relationship when the recipient asks or when promoting publicly (ASCI influencer guidelines for public promotion in India; FTC Endorsement Guides in the US — bake disclosure into AI-drafted templates so compliance is the default).
- **Type-specific annexes:** hiring success fees (flat, invoiced, compliant with state Shops & Establishments registrations; **never charge candidates** — predatory and in some jurisdictions illegal); consulting/vendor via marketplace order terms; **investment intros: no consideration, ever** (SEBI merchant-banker territory; US broker-dealer if it ever touches US persons); mentorship/speaking/community = non-monetary.
- **Anti-MLM guardrails in writing:** one level, no recruitment rewards, no purchase-to-participate, rewards funded by the buying business's campaign budget only.

## 6. Community Guidelines & Acceptable Use

Plain-language rules: no spam or scraped-contact abuse; no harassment/hate (IT Rules 2021 due-diligence categories incorporated); no fake identities or credentials; no gaming (rings, reciprocal-vouch farms, invite selling); no prohibited businesses in campaigns (gambling, crypto-investment schemes, MLM recruitment, weapons, adult, anything requiring licenses the poster lacks — pharma/finance need extra verification); moderation ladder (warn → feature-limit → suspend → ban) with notice + appeal (IT Rules require notice-and-appeal for takedowns); community hosts enforce norms but platform rules are the floor. **IT Rules milestone:** at 5M Indian users TrustOS likely becomes a "Significant Social Media Intermediary" — resident Chief Compliance Officer, nodal contact, monthly compliance reports; put it on the Phase-2 ops roadmap now.

## 7. Trust Index Policy (publish it — it's a moat)

A public, versioned policy: what the DTI is (contextual business-reputation, 0–1000), the component categories and weights (mirroring `_shared-context.md` §4 — publishing weights is a trust move; anti-gaming detail stays internal), what moves it, decay, that it **cannot be bought** (no paid product touches it), band-only external display, the explanation surface, appeal with human review and an SLA (e.g. 7 days), fraud adjustments with notice, and the Prohibited Use list for members and third parties. This one document is simultaneously: DPDP/GDPR profiling transparency, EU AI Act Art. 5 defense (contextual, contestable, no unrelated-context detriment), FCRA firewall (declared non-consumer-report + prohibited uses), and PR armor.

## 8. Tax & financial compliance (India launch)

- **GST:** TrustOS charges GST (18%) on platform fees/subscriptions/take-rate; referrers earning commissions make a taxable supply — below the ₹20L turnover threshold they're exempt from registration, but the platform's **e-commerce operator** posture needs a formal opinion on §9(5)/TCS applicability for marketplace services.
- **TDS:** commissions likely attract **§194H** (commission TDS) or **§194-O** (e-commerce operator) — get an opinion, implement whichever applies at the ledger-payout layer, issue Form 16A, collect PAN at T4 KYC (payout blocked without PAN; higher TDS u/s 206AA otherwise).
- **KYC/AML (PMLA):** ride the licensed payment partner's KYC/AML program; TrustOS adds velocity/fraud monitoring (06 §3); sanctions screening on payout.
- **Coins stay legally inert:** never purchasable, never redeemable for money, no user-to-user transfer → outside PPI/deposit/gift-card regimes. Any future change to this triggers full re-review (write that sentence into internal policy).
- **Corporate:** standard registrations (GST, professional tax, Shops & Establishments); if hiring-fee revenue grows, evaluate state-specific recruitment-agency registrations.

## 9. Expansion posture (build-once decisions)

| Jurisdiction | The one thing to decide early |
|---|---|
| **EU** | AI Act: keep DTI out of Annex III high-risk uses (no employment/credit screening — Prohibited Use already does this); GDPR Art. 22 rights already product-native; appoint EU rep + DPO at entry; SCCs for any India processing of EU data (or keep the EU cell fully self-contained — architecture already allows it) |
| **US** | FCRA firewall (§1); state privacy laws (CCPA/CPRA etc.) — the rights machinery generalizes; TCPA is *brutal* on SMS/calls (per-message statutory damages) — US messaging launch needs its own consent review; referral disclosures per FTC |
| **UAE/SEA** | PDPL/PDPA analogs are GDPR-shaped — the DPDP+GDPR build covers most of it; check UAE onshore/free-zone data rules and Singapore's DNC registry before SMS |

## 10. In-product compliance map (built vs. gaps)

| Obligation | Status in product |
|---|---|
| Purpose-specific consent at contact import | ✅ consent screen with explicit promises |
| Profiling transparency + contest | ✅ Trust profile explanation + "Request a review" |
| Erasure | ✅ designed (crypto-shred, 05 §10); Settings surface present |
| Quiet hours / frequency caps | ✅ automation engine (08 §4) |
| Referred-person consent | ✅ in business rules; gap: not yet enforced in the exemplar service code |
| Grievance officer + 24h/15d SLAs | ❌ ops hire + in-app "Report a grievance" surface — pre-launch requirement |
| TDS/PAN at payout | ❌ ledger-service payout milestone |
| DLT registration (SMS) | ❌ before the SMS channel activates |
| Terms/Policy acceptance flow | ❌ add checkbox + versioned acceptance log at onboarding step 2 (store doc version + timestamp — the acceptance log is the evidence) |
| Non-member erasure channel | ❌ public web form, pre-launch |

## 11. Sequencing

**Pre-launch (blockers):** ToS + Privacy + Referral Terms + Grievance policy executed by counsel; payment-partner contract (escrow structure sign-off); DPIA on trust score + contact graph; acceptance-logging in onboarding; grievance officer named; TDS opinion.
**Phase 1:** Trust Index Policy public; DLT + WhatsApp BSP compliance for campaigns; Business Terms + DPA for org features; refund policy live with marketplace.
**Phase 2+:** SSMI readiness (5M users), Significant Data Fiduciary readiness (DPO, audits), SOC 2 Type II for org sales, EU entry pack (rep, DPO, SCCs), API terms with Prohibited Use flow-down.

---
*Prepared as engineering-aligned legal architecture. Not legal advice; execution requires licensed counsel per jurisdiction — budget three separate workstreams: a fintech/payments opinion, a tax opinion (TDS/GST), and a data-protection review.*
