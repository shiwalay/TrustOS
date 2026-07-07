import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:trustos/core/sync/conflict_policy.dart';
import 'package:trustos/core/sync/pending_operation.dart';
import 'package:trustos/core/sync/pending_operation_store.dart';
import 'package:trustos/core/sync/sync_adapter.dart';
import 'package:trustos/core/sync/sync_engine.dart';
import 'package:trustos/core/sync/trustos_id.dart';

class _FixedClock implements Clock {
  _FixedClock(this.now);
  DateTime now;

  @override
  DateTime nowUtc() => now;
}

class _FakeAdapter implements SyncAdapter {
  final List<PendingOperation> pushed = [];
  final List<String> compensated = [];
  PushResult Function(PendingOperation op) onPush =
      (op) => PushResult.applied;

  @override
  EntityType get entityType => EntityType.referral;

  @override
  ConflictPolicy get policy => ConflictPolicy.queueAndConfirm;

  @override
  Future<PushResult> push(PendingOperation op) async {
    pushed.add(op);
    final result = onPush(op);
    if (result is PushTerminalFailure) compensated.add(op.entityId);
    return result;
  }

  @override
  Future<void> applyDelta(List<DeltaRecord> records) async {}
}

PendingOperation _op({
  required DateTime now,
  String? id,
  String? entityId,
}) {
  final opId = id ?? TrustosId.generate('ref', now: now);
  return PendingOperation(
    id: opId,
    entityType: EntityType.referral.wire,
    entityId: entityId ?? opId,
    opType: OpType.create,
    payloadJson: '{}',
    idempotencyKey: opId,
    conflictPolicy: ConflictPolicy.queueAndConfirm,
    createdAt: now,
    nextAttemptAt: now,
  );
}

void main() {
  late InMemoryPendingOperationStore store;
  late _FixedClock clock;
  late _FakeAdapter adapter;
  late SyncEngine engine;

  setUp(() {
    store = InMemoryPendingOperationStore();
    clock = _FixedClock(DateTime.utc(2026, 7, 7, 9));
    adapter = _FakeAdapter();
    engine = SyncEngine(
      store: store,
      clock: clock,
      jitter: Random(42),
      autoFlush: false,
    );
    engine.register(adapter);
  });

  group('enqueueWithLocalWrite', () {
    test('persists the op together with the local write', () async {
      var localWriteRan = false;
      await engine.enqueueWithLocalWrite(
        operation: _op(now: clock.now),
        localWrite: () async => localWriteRan = true,
      );

      expect(localWriteRan, isTrue);
      expect(await store.pendingCount(), 1);
      final due = await store.due(clock.now);
      expect(due.single.idempotencyKey, due.single.id,
          reason: 'client UUIDv7 id doubles as the Idempotency-Key');
    });
  });

  group('pushFlush', () {
    test('applied → op removed from queue', () async {
      await store.enqueue(_op(now: clock.now));
      await engine.pushFlush();

      expect(adapter.pushed, hasLength(1));
      expect(await store.pendingCount(), 0);
    });

    test('terminal failure → compensation ran, op removed', () async {
      adapter.onPush = (_) => PushResult.terminalFailure;
      final op = _op(now: clock.now);
      await store.enqueue(op);
      await engine.pushFlush();

      expect(adapter.compensated, [op.entityId]);
      expect(await store.pendingCount(), 0);
      expect(await store.deadLetters(), isEmpty);
    });

    test('retryable failure → op stays with backoff in the future', () async {
      adapter.onPush = (_) => PushResult.retryLater();
      await store.enqueue(_op(now: clock.now));
      await engine.pushFlush();

      expect(await store.pendingCount(), 1);
      expect(await store.due(clock.now), isEmpty,
          reason: 'rescheduled op is not due until backoff elapses');
      final due = await store.due(clock.now.add(SyncEngine.maxBackoff));
      expect(due.single.attempt, 1);
    });

    test('honors server Retry-After over computed backoff', () async {
      adapter.onPush = (_) => PushResult.retryLater(const Duration(minutes: 3));
      await store.enqueue(_op(now: clock.now));
      await engine.pushFlush();

      expect(await store.due(clock.now.add(const Duration(minutes: 2))),
          isEmpty);
      expect(
        await store.due(clock.now.add(const Duration(minutes: 3))),
        hasLength(1),
      );
    });

    test('FIFO per entity: a failed op blocks later ops for that entity, '
        'but not other entities', () async {
      adapter.onPush =
          (op) => op.entityId == 'ref_a' ? PushResult.retryLater() : PushResult.applied;

      // Same enqueue time (all due now); FIFO comes from id ordering.
      final t0 = clock.now;
      await store.enqueue(_op(now: t0, id: 'a1', entityId: 'ref_a'));
      await store.enqueue(_op(now: t0, id: 'a2', entityId: 'ref_a'));
      await store.enqueue(_op(now: t0, id: 'b1', entityId: 'ref_b'));

      await engine.pushFlush();

      expect(adapter.pushed.map((o) => o.id), ['a1', 'b1'],
          reason: 'a2 must not overtake the failed a1; b1 is independent');
    });

    test('dead-letters after max attempts — never silent loss', () async {
      adapter.onPush = (_) => PushResult.retryLater(Duration.zero);
      await store.enqueue(_op(now: clock.now));

      for (var i = 0; i < SyncEngine.maxAttempts; i++) {
        await engine.pushFlush();
      }

      final deadLetters = await store.deadLetters();
      expect(deadLetters, hasLength(1));
      expect(deadLetters.single.attempt, SyncEngine.maxAttempts);
      expect(await store.due(clock.now.add(const Duration(days: 1))), isEmpty);
    });

    test('dead-letters ops older than 48 h regardless of attempts', () async {
      adapter.onPush = (_) => PushResult.retryLater(Duration.zero);
      await store.enqueue(_op(now: clock.now));

      clock.now = clock.now.add(SyncEngine.maxOpAge);
      await engine.pushFlush();

      expect(await store.deadLetters(), hasLength(1));
    });
  });

  group('backoff schedule', () {
    test('is exponential and capped at 15 minutes', () {
      final first = engine.backoffFor(1);
      expect(first, greaterThanOrEqualTo(const Duration(seconds: 10)));
      expect(first, lessThan(const Duration(seconds: 12)));
      expect(engine.backoffFor(20), SyncEngine.maxBackoff);
    });
  });

  group('TrustosId', () {
    test('UUIDv7 ids are lexicographically time-ordered', () {
      final earlier = TrustosId.generate('ref', now: DateTime.utc(2026, 1, 1));
      final later = TrustosId.generate('ref', now: DateTime.utc(2026, 1, 2));
      expect(earlier.compareTo(later), lessThan(0));
    });

    test('carries the entity prefix and v7 marker', () {
      final id = TrustosId.generate('ref');
      expect(id, startsWith('ref_'));
      // Version nibble is the first char of the third group.
      expect(id.split('-')[2][0], '7');
    });
  });
}
