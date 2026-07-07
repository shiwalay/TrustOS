import 'pending_operation.dart';

/// Persistence boundary for the op queue. Production implementation is
/// Drift-backed ([lib/core/storage/drift_pending_operation_store.dart]);
/// tests use an in-memory fake. Keeping the engine off the concrete DB is
/// what makes the queue unit-testable without codegen or a device.
abstract interface class PendingOperationStore {
  /// Atomically persist [op] together with the feature's local write —
  /// either both exist or neither (09-mobile-architecture.md §3.3).
  Future<void> enqueue(
    PendingOperation op, {
    Future<void> Function()? localWrite,
  });

  /// Ops due for dispatch (state == pending, nextAttemptAt <= now),
  /// ordered by id (UUIDv7 → FIFO). At most one in-flight op per
  /// (entityType, entityId) — enforced by the engine, fed by this ordering.
  Future<List<PendingOperation>> due(DateTime now);

  Future<void> update(PendingOperation op);

  /// Op completed (applied or terminal-failure-compensated) — remove it.
  Future<void> remove(String id);

  /// Dead-letter surface: Settings → "Pending changes" (10-ux-design.md §7).
  Future<List<PendingOperation>> deadLetters();

  Future<int> pendingCount();
}

/// In-memory store — used by tests and as a placeholder until the Drift
/// implementation is generated (`dart run build_runner build`).
class InMemoryPendingOperationStore implements PendingOperationStore {
  final Map<String, PendingOperation> _ops = {};

  @override
  Future<void> enqueue(
    PendingOperation op, {
    Future<void> Function()? localWrite,
  }) async {
    // Same all-or-nothing contract as the Drift transaction.
    await localWrite?.call();
    _ops[op.id] = op;
  }

  @override
  Future<List<PendingOperation>> due(DateTime now) async {
    final due = _ops.values
        .where((o) =>
            o.state == OpState.pending && !o.nextAttemptAt.isAfter(now))
        .toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    return due;
  }

  @override
  Future<void> update(PendingOperation op) async {
    _ops[op.id] = op;
  }

  @override
  Future<void> remove(String id) async {
    _ops.remove(id);
  }

  @override
  Future<List<PendingOperation>> deadLetters() async =>
      _ops.values.where((o) => o.state == OpState.deadLetter).toList()
        ..sort((a, b) => a.id.compareTo(b.id));

  @override
  Future<int> pendingCount() async =>
      _ops.values.where((o) => o.state != OpState.deadLetter).length;
}
