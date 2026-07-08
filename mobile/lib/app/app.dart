import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/design_system/theme/app_theme.dart';
import '../core/l10n/generated/app_localizations.dart';
import 'di/providers.dart';
import 'router/router.dart';

/// MaterialApp.router — one visual language (Neo-Minimal Intelligence),
/// light-committed so every screen is identical regardless of the OS theme
/// (design directive: one style, zero exceptions).
class TrustOsApp extends ConsumerWidget {
  const TrustOsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final config = ref.watch(flavorConfigProvider);

    return MaterialApp.router(
      title: config.appTitle,
      theme: AppTheme.light(),
      darkTheme: AppTheme.light(),
      themeMode: ThemeMode.light,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      routerConfig: router,
    );
  }
}
