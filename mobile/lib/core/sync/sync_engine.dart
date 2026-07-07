import 'dart:async';
import 'dart:math';

import 'pending_operation.dart';
import 'pending_operation_store.dart';
import 'sync_adapter.dart';

/// Clock seam so tests can control time (09-mobile-architecture.md §8).
abstract interface class Clock {
  DateTime nowUtc();
}

class SystemClock implements Clock {
  const SystemClock();
  @override
  DateTime nowUtc() => DateTime.now().toUtc();
}

/// SyncEngine skeleton — 09-mobile-architecture.md §4.
///
/// One queue, one scheduler: features register a [SyncAdapter] (entity type +
/// serializers + conflict policy); the engine owns dispatch order, backoff,
/// idempotency and dead-lettering. Push always precedes pull in a cycle
/// (flush our intent, then read merged truth).
///
/// Skeleton scope: full push loop + policy registry; pull delegates to the
/// registered adapter with an empty page (the delta HTTP client lands with
/// the generated SDK). Connectivity state machine (§4.5) is stubbed as
/// always-online.
class SyncEngine {
  SyncEngine({
    required PendingOperationStore store,
    Clock clock = const SystemClock(),
    Random? jitter,
    this.autoFlush = true,
  })  : _store = store,
        _clock = clock,
        _jitter = jitter ?? Random();

  /// When false, enqueue does not kick an opportunistic background flush —
  /// tests drive [pushFlush] explicitly for determinism.
  final bool autoFlush;

  static const int maxAttempts = 10;
  static const Duration maxOpAge = Duration(hours: 48);
  static const Duration baseBackoff = Duration(seconds: 5);
  static const Duration maxBackoff = Duration(minutes: 15);

  final PendingOperationStore _store;
  final Clock _clock;
  final Random _jitter;
  final Map<EntityType, SyncAdapter> _adapters = {};

  bool _started = false;

  /// Feature manifests call this at composition time.
  void register(SyncAdapter adapter) {
    _adapters[adapter.entityType] = adapter;
  }

  SyncAdapter adapterFor(EntityType type) {
    final adapter = _adapters[type];
    if (adapter == null) {
      throw StateError('No SyncAdapter registered for ${type.wire}');
    }
    return adapter;
  }

  /// Phase-2 startup hook (bootstrap.dart): flush queue, then priority pulls.
  Future<void> start() async {
    if (_started) return;
    _started = true;
    await syncCycle();
  }

  /// One full cycle: push flush → pulls. Triggered by connectivity recovery,
  /// silent push (`sync.wake`), foreground resume, or an enqueued op.
  Future<void> syncCycle() async {
    await pushFlush();
    for (final type in _adapters.keys) {
      await pullNow(type);
    }
  }

  // ---------------------------------------------------------------- write

  /// Single transaction: feature-local row + queued op — either both exist
  /// or neither (09 §3.3). This is THE write path for every mutation.
  Future<void> enqueueWithLocalWrite({
    required PendingOperation operation,
    Future<void> Function()? localWrite,
  }) async {
    await _store.enqueue(operation, localWrite: localWrite);
    // Opportunistic flush; offline this becomes a no-op retry-later.
    if (autoFlush) unawaited(pushFlush());
  }

  // ----------------------------------------------------------------- push

  /// Drains due operations. FIFO per (entityType, entityId): a later update
  /// to an entity never overtakes an earlier one; independent entities may
  /// push concurrently (skeleton dispatches sequentially for determinism).
  Future<void> pushFlush() async {
    final now = _clock.nowUtc();
    final due = await _store.due(now);
    final blockedEntities = <String>{};

    for (final op in due) {
      final entityKey = '${op.entityType}/${op.entityId}';
      if (blockedEntities.contains(entityKey)) continue;

      final result = await _pushOne(op);
      if (result is! _PushApplied) {
        // Keep FIFO: later ops for this entity wait for this one.
        blockedEntities.add(entityKey);
      }
    }
  }

  Future<_PushOutcome> _pushOne(PendingOperation op) async {
    final type = EntityType.values.firstWhere((t) => t.wire == op.entityType);
    final adapter = adapterFor(type);
    await _store.update(op.copyWith(state: OpState.inFlight));

    PushResult result;
    try {
      result = await adapter.push(op);
    } on Exception {
      result = PushResult.retryLater();
    }

    switch (result) {
      case PushRetryLater(:final retryAfter):
        await _store.update(_reschedule(op, retryAfter));
        return const _PushRetry();
      case PushApplied():
      case PushTerminalFailure():
        // Applied → server truth lands via delta/adapter upsert.
        // Terminal → adapter already ran its compensating local write.
        await _store.remove(op.id);
        return const _PushApplied();
    }
  }

  /// Backoff: `min(2^attempt × 5 s + jitter, 15 min)`, honoring Retry-After.
  /// After 10 attempts or 48 h → deadLetter (surfaced in Settings →
  /// "Pending changes"; silent data loss is prohibited — 09 §4.3).
  PendingOperation _reschedule(PendingOperation op, Duration? retryAfter) {
    final now = _clock.nowUtc();
    final attempt = op.attempt + 1;
    final expired = now.difference(op.createdAt) >= maxOpAge;
    if (attempt >= maxAttempts || expired) {
      return op.copyWith(attempt: attempt, state: OpState.deadLetter);
    }
    final backoff = retryAfter ?? backoffFor(attempt);
    return op.copyWith(
      attempt: attempt,
      state: OpState.pending,
      nextAttemptAt: now.add(backoff),
    );
  }

  Duration backoffFor(int attempt) {
    final exponential = baseBackoff * pow(2, attempt).toInt();
    final jitterMs = _jitter.nextInt(1000);
    final total = exponential + Duration(milliseconds: jitterMs);
    return total > maxBackoff ? maxBackoff : total;
  }

  // ----------------------------------------------------------------- pull

  /// Cheap coalesced pull request (repositories call this on watch()).
  Future<void> requestPull(EntityType type, {String scope = '*'}) =>
      pullNow(type, scope: scope);

  /// Cursor-delta pull (09 §4.2). Skeleton: no HTTP client yet — applies an
  /// empty page so the call graph, registry and transaction shape are real.
  Future<void> pullNow(EntityType type, {String scope = '*'}) async {
    final adapter = adapterFor(type);
    // TODO(sync): GET /v1/sync/delta?entity=&scope=&cursor=&limit=200,
    // loop pages, persist cursor per (entityType, scope) in sync_cursors.
    await adapter.applyDelta(const []);
  }

  // ------------------------------------------------------------ dead letter

  Future<List<PendingOperation>> deadLetters() => _store.deadLetters();

  Future<int> pendingCount() => _store.pendingCount();
}

sealed class _PushOutcome {
  const _PushOutcome();
}

final class _PushApplied extends _PushOutcome {
  const _PushApplied();
}

final class _PushRetry extends _PushOutcome {
  const _PushRetry();
}
