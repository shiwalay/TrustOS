import 'package:equatable/equatable.dart';

import 'conflict_policy.dart';

/// Queue states — 09-mobile-architecture.md §4.1.
enum OpState { pending, inFlight, failed, deadLetter }

/// `action` = non-CRUD verb (e.g. accept_intro).
enum OpType { create, update, delete, action }

/// One queued mutation. `id` is a client-generated UUIDv7: it is the FIFO
/// ordering (lexicographic == chronological) AND doubles as the
/// `Idempotency-Key`, so retries after a lost response are exact replays,
/// never duplicates (shared-context §5).
class PendingOperation extends Equatable {
  const PendingOperation({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.opType,
    required this.payloadJson,
    required this.idempotencyKey,
    required this.conflictPolicy,
    required this.createdAt,
    required this.nextAttemptAt,
    this.actorType = 'user',
    this.actorId = '',
    this.attempt = 0,
    this.state = OpState.pending,
    this.lastErrorType,
    this.baseVersionJson,
  });

  final String id;
  final String entityType;
  final String entityId;
  final OpType opType;
  final String payloadJson;
  final String idempotencyKey;
  final ConflictPolicy conflictPolicy;

  /// Actor model (shared-context §1): 'user' | 'org' + acting principal id.
  final String actorType;
  final String actorId;

  final int attempt;
  final DateTime createdAt;
  final DateTime nextAttemptAt;
  final OpState state;

  /// RFC 9457 problem `type` of the last failure, for the dead-letter UI.
  final String? lastErrorType;

  /// Snapshot for LWW field-merge (09 §4.4) — null for queueAndConfirm ops.
  final String? baseVersionJson;

  PendingOperation copyWith({
    int? attempt,
    DateTime? nextAttemptAt,
    OpState? state,
    String? lastErrorType,
  }) =>
      PendingOperation(
        id: id,
        entityType: entityType,
        entityId: entityId,
        opType: opType,
        payloadJson: payloadJson,
        idempotencyKey: idempotencyKey,
        conflictPolicy: conflictPolicy,
        actorType: actorType,
        actorId: actorId,
        attempt: attempt ?? this.attempt,
        createdAt: createdAt,
        nextAttemptAt: nextAttemptAt ?? this.nextAttemptAt,
        state: state ?? this.state,
        lastErrorType: lastErrorType ?? this.lastErrorType,
        baseVersionJson: baseVersionJson,
      );

  @override
  List<Object?> get props => [id, state, attempt, nextAttemptAt, lastErrorType];
}
