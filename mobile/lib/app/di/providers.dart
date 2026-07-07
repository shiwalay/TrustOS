import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/analytics/analytics.dart';
import '../../core/networking/auth_interceptor.dart';
import '../../core/networking/dio_client.dart';
import '../../core/storage/app_database.dart';
import '../../core/storage/drift_pending_operation_store.dart';
import '../../core/sync/pending_operation_store.dart';
import '../../core/sync/sync_engine.dart';
import '../flavors.dart';

/// Composition root (09-mobile-architecture.md app/di): app-wide singletons.
/// Feature manifests (`features/*/<feature>_module.dart`) build on these.
/// Tests override at the repository/use-case level, never mock widgets.

/// Overridden in bootstrap with the flavor picked via --dart-define.
final flavorConfigProvider = Provider<FlavorConfig>(
  (ref) => throw UnimplementedError('Overridden in bootstrap()'),
);

final tokenProviderProvider = Provider<TokenProvider>(
  (ref) => const StubTokenProvider(),
);

final dioProvider = Provider<Dio>(
  (ref) => buildDio(
    baseUrl: ref.watch(flavorConfigProvider).apiBaseUrl,
    tokens: ref.watch(tokenProviderProvider),
  ),
);

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.open();
  ref.onDispose(db.close);
  return db;
});

final pendingOperationStoreProvider = Provider<PendingOperationStore>(
  (ref) => DriftPendingOperationStore(ref.watch(databaseProvider)),
);

final clockProvider = Provider<Clock>((ref) => const SystemClock());

final syncEngineProvider = Provider<SyncEngine>(
  (ref) => SyncEngine(
    store: ref.watch(pendingOperationStoreProvider),
    clock: ref.watch(clockProvider),
  ),
);

final analyticsProvider = Provider<Analytics>((ref) => const DebugAnalytics());
