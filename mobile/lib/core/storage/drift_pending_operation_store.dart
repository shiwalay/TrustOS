import 'package:drift/drift.dart';

import '../sync/pending_operation.dart';
import '../sync/pending_operation_store.dart';
import 'app_database.dart';

/// Drift-backed op queue (09-mobile-architecture.md §4.1). Uses generated
/// row/companion types — requires build_runner output.
class DriftPendingOperationStore implements PendingOperationStore {
  DriftPendingOperationStore(this._db);

  final AppDatabase _db;

  @override
  Future<void> enqueue(
    PendingOperation op, {
    Future<void> Function()? localWrite,
  }) =>
      // The transactional guarantee: feature row + queued op, all or nothing.
      _db.transaction(() async {
        await localWrite?.call();
        await _db.into(_db.pendingOperations).insert(_toCompanion(op));
      });

  @override
  Future<List<PendingOperation>> due(DateTime now) async {
    final rows = await (_db.select(_db.pendingOperations)
          ..where((t) =>
              t.state.equalsValue(OpState.pending) &
              t.nextAttemptAt.isSmallerOrEqualValue(now))
          ..orderBy([(t) => OrderingTerm.asc(t.id)])) // UUIDv7 → FIFO
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<void> update(PendingOperation op) => _db
      .into(_db.pendingOperations)
      .insertOnConflictUpdate(_toCompanion(op));

  @override
  Future<void> remove(String id) =>
      (_db.delete(_db.pendingOperations)..where((t) => t.id.equals(id))).go();

  @override
  Future<List<PendingOperation>> deadLetters() async {
    final rows = await (_db.select(_db.pendingOperations)
          ..where((t) => t.state.equalsValue(OpState.deadLetter))
          ..orderBy([(t) => OrderingTerm.asc(t.id)]))
        .get();
    return rows.map(_toModel).toList();
  }

  @override
  Future<int> pendingCount() async {
    final count = _db.pendingOperations.id.count();
    final query = _db.selectOnly(_db.pendingOperations)
      ..addColumns([count])
      ..where(_db.pendingOperations.state
          .equalsValue(OpState.deadLetter)
          .not());
    final row = await query.getSingle();
    return row.read(count) ?? 0;
  }

  PendingOperationsCompanion _toCompanion(PendingOperation op) =>
      PendingOperationsCompanion(
        id: Value(op.id),
        entityType: Value(op.entityType),
        entityId: Value(op.entityId),
        opType: Value(op.opType),
        payloadJson: Value(op.payloadJson),
        idempotencyKey: Value(op.idempotencyKey),
        conflictPolicy: Value(op.conflictPolicy),
        actorType: Value(op.actorType),
        actorId: Value(op.actorId),
        attempt: Value(op.attempt),
        createdAt: Value(op.createdAt),
        nextAttemptAt: Value(op.nextAttemptAt),
        state: Value(op.state),
        lastErrorType: Value(op.lastErrorType),
        baseVersionJson: Value(op.baseVersionJson),
      );

  PendingOperation _toModel(PendingOperationRow row) => PendingOperation(
        id: row.id,
        entityType: row.entityType,
        entityId: row.entityId,
        opType: row.opType,
        payloadJson: row.payloadJson,
        idempotencyKey: row.idempotencyKey,
        conflictPolicy: row.conflictPolicy,
        actorType: row.actorType,
        actorId: row.actorId,
        attempt: row.attempt,
        createdAt: row.createdAt,
        nextAttemptAt: row.nextAttemptAt,
        state: row.state,
        lastErrorType: row.lastErrorType,
        baseVersionJson: row.baseVersionJson,
      );
}
