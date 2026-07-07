# TrustOS Mobile (Flutter)

Offline-first Flutter client. The architecture authority is
[`docs/09-mobile-architecture.md`](../docs/09-mobile-architecture.md) (feature-first Clean
Architecture, Riverpod, Drift, sync engine) with UX per
[`docs/10-ux-design.md`](../docs/10-ux-design.md) (Ember design system, 5-tab IA) and platform
invariants per [`docs/_shared-context.md`](../docs/_shared-context.md).

## Run it

```bash
flutter pub get                # also runs flutter gen-l10n (l10n.yaml)
dart run build_runner build    # Drift codegen (*.g.dart) — required after schema changes
flutter run --dart-define=FLAVOR=dev   # flavors: dev | stage | prod
flutter analyze && flutter test
```

> Verified with Flutter 3.44.5: `flutter analyze` — no issues; `flutter test` — 21/21 passing.
> Generated files (`*.g.dart`, `lib/core/l10n/generated/`) are gitignored — run the codegen
> steps after a fresh clone.

## Architecture map

Layout follows docs/09 §2, collapsed to a single app package for the skeleton (the melos
workspace with `packages/{trustos_api, trustos_graphql, design_system, sync_engine}` splits out
once contracts are generated — `core/design_system` and `core/sync` are written to lift out
cleanly).

```
lib/
├── app/                  bootstrap (phased startup §6.1), flavors, DI composition root,
│   │                     go_router 5-tab StatefulShellRoute (Home·Network·Act·Communities·You),
│   └── shell/            AppShell scaffold + Act hub (navigation chrome)
├── core/
│   ├── design_system/    Ember tokens (10-ux §4.1), light/dark theme, TrustBandColors
│   │                     ThemeExtension (§4.2), TrustBandRing (semantics per 09 §7)
│   ├── networking/       dio builder, auth interceptor stub, RFC 9457 → AppException mapper
│   ├── errors/           sealed AppException taxonomy (terminal vs retryable)
│   ├── storage/          Drift AppDatabase, sync tables (09 §4.1), Drift op-queue store
│   ├── sync/             pure-Dart sync engine: UUIDv7 ids (= idempotency keys), push loop
│   │                     with backoff/dead-letter, ConflictPolicy {serverWins, lwwMerge,
│   │                     queueAndConfirm}, SyncAdapter registry, cursor-pull skeleton
│   ├── analytics/        typed facade (debug logger impl)
│   └── l10n/             ARB en + hi → generated AppLocalizations
└── features/
    ├── referrals/        ★ the real vertical slice (domain / data / presentation, 09 §2.1)
    └── <15 others>/      three-layer skeletons + placeholder screens wired into the router
```

## Real vs stub

**Real (implemented + tested):**
- Referrals slice end-to-end: `Referral` entity + status machine (incl. `settled`), `Money`/`E164`
  value objects, `SubmitReferral` use-case (consent hard-gate), offline-first repository
  (Drift watch + queue-and-confirm submit — never optimistic on money), sync adapter with
  terminal-rejection rollback, list screen (loading/empty/error/data), submit sheet,
  status chips with visible "Pending sync".
- Sync engine: transactional enqueue (op + local write), FIFO-per-entity push loop,
  exponential backoff capped 15 min honoring Retry-After, dead-letter after 10 attempts/48 h,
  UUIDv7 mint.
- Ember theme (light + dark), trust-band semantics, TrustBandRing, 5-tab shell + route table.

**Stub (compiles, clearly marked):**
- Delta pull HTTP client (engine applies empty pages; cursors table ready), connectivity state
  machine, auth/session (token provider returns null; auth redirect forced "authenticated"),
  cert pinning, SQLCipher key vault, notifications, the 15 module placeholder screens,
  analytics transport.

## Tests

```bash
flutter test
```
- `test/features/referrals/domain/` — use-case validation + entity rules (pure Dart).
- `test/core/sync/` — queue behavior on an in-memory store: enqueue atomicity, FIFO per entity,
  backoff schedule, Retry-After, dead-lettering, UUIDv7 ordering.
- `test/features/referrals/presentation/` — widget test of the list screen in
  loading/data/empty/error via provider overrides (no widget mocks).

## Deviations from docs/09 (deliberate, skeleton-stage)

| Deviation | Why |
|---|---|
| Single app package instead of melos workspace | No generated SDK/GraphQL packages exist yet; folder shapes match the doc so extraction is mechanical. |
| Hand-written Riverpod providers instead of `@riverpod` codegen | Same AsyncValue surface, one less build_runner dependency; swap is mechanical. |
| Single `main.dart` + `--dart-define=FLAVOR` instead of `main_<flavor>.dart` | Task spec: flavors stub via dart-define; per-flavor entrypoints return with android/ios flavor configs. |
| `ReferralStatus` includes `settled` (doc's exemplar omits it) | Backend state machine + `referral.commission.settled.v1` are canonical; task requires it. |
| `SyncEngine` depends on a `PendingOperationStore` interface (Drift impl + in-memory) | Keeps engine pure Dart and unit-testable without codegen; Drift store is the production binding. |
| Plain SQLite (drift_flutter), not SQLCipher | Vault/keystore work is a security milestone; schema unchanged. |
