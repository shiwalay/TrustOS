# TrustOS — Neo-Minimal Intelligence Design System

> **Less interface. More intelligence.** An alternate design language for TrustOS: ultra-clean, one-accent, AI-native — inspired by Apple HIG, Linear, Notion, and Arc. This document is the system; the live proof is the Neo dashboard in-app (`Settings → Neo-Minimal dashboard`, route `/neo`). It is delivered **non-destructively** — the navy/gold premium brand ([`10-ux-design.md`](10-ux-design.md)) remains intact. Decide whether to adopt Neo-Minimal as the app-wide language before we roll it across all surfaces.

## 0. The two directions, honestly

| | Ember (current, shipped) | Neo-Minimal (this doc) |
|---|---|---|
| Feel | Premium, warm, editorial | Calm, fast, intelligent, utilitarian |
| Ground | Midnight navy / warm ivory | Near-white `#FAFAFA` |
| Accent | Champagne gold | Signal blue `#2563EB` |
| Type | Playfair serif + system sans | Inter (SF Pro on Apple) |
| Best when | Selling trust as luxury (landing, brand) | Daily-driver product surfaces where speed & clarity win |
Both are legitimate. Neo-Minimal is the stronger choice for the *working* app; Ember is the stronger choice for *brand/marketing* surfaces. A defensible end-state uses Neo-Minimal in-product and keeps Ember for the landing site.

## 1. Foundations

**Color** (used sparingly — color communicates action & status, never decoration):
`--bg #FAFAFA` · `--surface #FFFFFF` · `--text #111827` · `--text-2 #6B7280` · `--divider #E5E7EB` · `--accent #2563EB` · `--success #22C55E` · `--warning #F59E0B` · `--error #EF4444`. Accent-soft = accent @ 8%. **Color is never the only signal** — pair with icon + label (WCAG 2.2 AA).

**Spacing** — strict 8-pt system: 4 · 8 · 12 · 16 · 20 · 24 · 32 · 40 · 48 · 64. Screen gutter 24. Card padding 20.

**Radii** — 12 (small/chips), 16 (controls/quick-actions), 20 (cards/sheets). **Elevation** — one soft shadow token (`0 4 12 rgba(17,24,39,.04)`), used only on primary content cards; everything else uses 1px `--divider` hairlines.

**Type scale** (Inter): Display 36 / H1 30 / H2 24 / H3 20 / Body 16 / Small 14 / Caption 12. Line-height 1.4–1.6, left-aligned, weight only to emphasize (400 body, 600 emphasis, 700 display). Tight tracking on display (−0.5).

**Touch targets** ≥ 44×44. **Motion** 150–300ms, spring for tap (soft scale 0.98), fade for content, standard for pages; `prefers-reduced-motion` honored. Haptics on commit actions only.

## 2. Component library (mapped to the brief)

Implemented in `features/neo/presentation/neo_tokens.dart` + the dashboard; the rest specced here.

- **Buttons** — Primary (filled accent, 48h, radius 16), Secondary (surface + divider border), Tertiary (accent text), Icon (44×44, optional status dot).
- **Cards** — Information (surface + soft shadow, radius 20), Statistics/KPI (big number + minimal linear progress + delta), Profile (avatar + identity + band pill), **AI Insight** (surface + 1px accent border, `RECOMMENDED FOR YOU` eyebrow, one action) and **AI Summary** (accent-soft fill, `insights` glyph).
- **Inputs** — Text/Search (surface, 1px divider, radius 16, 48h, focus = 2px accent ring), Dropdown, Date, **OTP** (6 divided cells), Multi-select chips. Labels above, helper/error below; error state = 1px `--error` + message (never color alone).
- **Navigation** — Bottom nav (surface, hairline top, 5 tabs, active = accent icon+label), Sticky header (avatar + greeting + notification icon w/ dot), Floating action, Breadcrumb where depth warrants.
- **Lists** — List item (36px tinted icon tile + title/subtitle + trailing timestamp), Expandable section, Timeline, Activity feed (hairline-divided).
- **Badges** — Status pill (tinted 12%), Notification dot, Achievement, Priority (icon+label, never color-only).
- **Progress** — Ring, Linear (6px, radius 999), Step indicator.
- **Dialogs** — Bottom sheet (radius 20 top, grabber), Modal, Confirmation, Success screen (checkmark + single CTA).
- **Empty states** — light line-illustration + one sentence + single CTA.
- **Loading** — skeleton shimmer (divider↔#F3F4F6), progressive load, optimistic UI.

## 3. Screen specifications (brief's deliverable template)

### 3.1 Dashboard / Home — *built live at `/neo`*
- **UX goal:** understand your standing and the single best next action in ≤ 5 seconds.
- **Layout:** status bar → sticky header (avatar · "Good evening, Swapnil" · notification) → **KPI card** (Trust Index 712/1000, minimal linear progress, "▲ 8 this month · 138 to Platinum") → **Recommended-for-you** AI insight ("Reconnect with Rohan Mehta", primary CTA + Later) → Quick actions (Ask/Offer · Refer · Briefing · Invite) → Recent activity feed → **AI summary** (accent-soft: "3 campaigns match — ~₹6,000 this week") → bottom nav.
- **Content hierarchy:** one KPI, one recommended action, everything else scannable and secondary.
- **Interaction/micro:** pull-to-refresh (accent spinner) re-runs skeleton→content; tap = soft-scale; CTAs give immediate feedback; haptic on "Draft a message".
- **States:** *Loading* = KPI/insight/activity skeletons (shipped). *Empty* (new user) = "Import contacts to see your network" single CTA. *Error* = inline card "Couldn't load your dashboard · Retry".
- **A11y:** header greeting + name as one semantic label; KPI announces "712 of 1000, Gold, up 8 this month"; targets ≥44; contrast AA (text on surface = 14.4:1); notification dot has text alt.
- **Responsive:** single column; quick-actions wrap 4→2 under 340pt; cards edge-to-edge with 24 gutters.
- **Dev notes:** `Theme(Neo.theme())` scopes the language; `CustomScrollView` + `RefreshIndicator`; skeleton via `AnimatedBuilder`; content is demo data (production → BFF).

### 3.2 Trust profile — condensed
- **Goal:** explain the 712, factor by factor, and offer recourse. **Layout:** big number + band pill → 9 component rows (label · linear progress · points) → recent movements (green/amber deltas w/ causes) → "Request a review" tertiary. **States:** loading skeleton rows; empty "score builds as you act"; error retry. **A11y:** each factor row is one semantic group; deltas carry ▲/▼ glyphs, not color alone.

### 3.3 Ask & Offer board — condensed
- **Goal:** post/scan needs & offers, act or relay. **Layout:** segmented filter (All/Asks/Offers) → post cards (type pill + category, title, body, author band·city, AI match hint, `I can help`/`Push`) → FAB "Post". **Micro:** relay opens a bottom sheet of fitting contacts; success toast "you're the connector". **Empty:** "Nothing yet — post the first ask". **Error:** inline retry.

### 3.4 Referral submit — condensed
- **Goal:** submit in ≤ 3 taps, never optimistic on money. **Layout:** campaign header (reward, terms) → contact picker → confirm → **success screen** (checkmark, "Queued — you'll be notified when it settles"). **States:** offline → "Saved · will send when online" (queue-and-confirm); error = field-level, never destructive.

### 3.5 Onboarding — condensed
- **Goal:** aha in < 3 min. **Layout:** 5 steps (Welcome · Invitation · Verify · Import · Reveal), step-dots, one primary CTA per screen, honest skip. **Micro:** 320ms emphasized page transitions; OTP auto-advance. **A11y:** "Step N of 5" announced.

## 4. Adoption path (if you choose Neo-Minimal app-wide)

1. Promote `neo_tokens.dart` to `core/design_system` as the product theme; keep Ember tokens for the landing site.
2. Reskin in dependency order: shared components → Home → Trust → Network/Board → the rest (each screen already has a spec above).
3. Bundle Inter (done), retire Playfair from in-product surfaces (keep for landing).
4. Golden-test the component library to lock the system.

*Related: [`10-ux-design.md`](10-ux-design.md) (Ember system), live proof at route `/neo`.*
