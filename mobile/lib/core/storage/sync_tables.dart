import 'package:drift/drift.dart';

import '../sync/conflict_policy.dart';
import '../sync/pending_operation.dart';

/// Sync-engine Drift tables — 09-mobile-architecture.md §4.1.
/// Data classes renamed to avoid clashing with the domain model
/// [PendingOperation] in core/sync.
@DataClassName('PendingOperationRow')
@TableIndex(name: 'idx_pending_ops_dispatch', columns: {#state, #nextAttemptAt})
class PendingOperations extends Table {
  TextColumn get id => text()(); //             UUIDv7 — doubles as ordering
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get opType => textEnum<OpType>()();
  TextColumn get payloadJson => text()();
  TextColumn get idempotencyKey => text()(); // sent as Idempotency-Key header
  TextColumn get conflictPolicy => textEnum<ConflictPolicy>()();
  TextColumn get actorType => text()(); //      'user' | 'org' (shared-context §1)
  TextColumn get actorId => text()();
  IntColumn get attempt => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get nextAttemptAt => dateTime()();
  TextColumn get state => textEnum<OpState>()();
  TextColumn get lastErrorType => text().nullable()(); // RFC 9457 problem `type`
  TextColumn get baseVersionJson =>
      text().nullable()(); //                   snapshot for LWW field-merge (§4.4)

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('SyncCursorRow')
class SyncCursors extends Table {
  TextColumn get entityType => text()();
  TextColumn get scope =>
      text().withDefault(const Constant('*'))(); // e.g. campaignId
  TextColumn get cursor => text()(); //          opaque base64 (shared-context §5)
  DateTimeColumn get lastSyncedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {entityType, scope};
}
