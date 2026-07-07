import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/theme/app_theme.dart';
import '../core/l10n/generated/app_localizations.dart';
import 'di/providers.dart';
import 'router/router.dart';

/// MaterialApp.router — Ember light/dark themes, locale resolution from
/// generated AppLocalizations (en + hi in the skeleton; launch set per
/// 09-mobile-architecture.md §7).
class TrustOsApp extends ConsumerWidget {
  const TrustOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final config = ref.watch(flavorConfigProvider);

    return MaterialApp.router(
      title: config.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
