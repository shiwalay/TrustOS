import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/demo/demo_seed.dart';
import '../core/session/onboarding_state.dart';
import '../features/referrals/referrals_module.dart';
import 'app.dart';
import 'di/providers.dart';
import 'flavors.dart';

/// Phased startup per 09-mobile-architecture.md §6.1.
///
/// PHASE 0/1 (blocking, budget 650 ms total): crash guard, flavor config,
/// ProviderScope creation, router initial location. Nothing on this path may
/// touch the network — first frame paints from Drift.
///
/// PHASE 2+ (post-first-frame): Sentry/OTel init, FCM token refresh, remote
/// flags, sync-engine start (push flush → priority pulls). Wired as a
/// post-frame callback; each item is a stub in this skeleton.
Future<void> bootstrap(Flavor flavor) async {
  WidgetsFlutterBinding.ensureInitialized();

  // PHASE 0 — crash guard stub (Sentry attaches here in a later milestone).
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
  };

  // Fast prefs read is on the allowed startup path (09 §6.1) — the router's
  // onboarding redirect needs it before the first frame.
  final prefs = await SharedPreferences.getInstance();

  final container = ProviderContainer(
    overrides: [
      flavorConfigProvider.overrideWithValue(FlavorConfig.of(flavor)),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
  );

  // PHASE 2 — deferred: seed demo data (no-op when populated), register
  // feature sync adapters, then start the engine (push flush → priority
  // pulls) after the first frame.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    unawaited(
      DemoSeeder.seedIfEmpty(container.read(databaseProvider)).then((_) {
        container.read(referralsSyncRegistrationProvider);
        unawaited(container.read(syncEngineProvider).start());
      }),
    );
  });

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TrustOsApp(),
    ),
  );
}
