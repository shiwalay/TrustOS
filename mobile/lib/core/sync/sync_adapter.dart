import 'conflict_policy.dart';
import 'pending_operation.dart';

/// Entity classes registered with the sync engine. `wire` is the value used
/// in `GET /v1/sync/delta?entity=…` and in pending_operations.entity_type.
enum EntityType {
  referral('referral'),
  referralCampaign('referral_campaign'),
  contact('contact'),
  relationship('relationship'),
  deal('deal'),
  campaign('campaign'),
  communityPost('community_post');

  const EntityType(this.wire);
  final String wire;
}

/// One record from the cursor-delta feed (09 §4.2). Tombstones delete rows
/// client-side (e.g. losing access to a community).
class DeltaRecord {
  const DeltaRecord({
    required this.entityId,
    required this.serverVersion,
    required this.isTombstone,
    this.payload = const {},
  });

  final String entityId;
  final int serverVersion;
  final bool isTombstone;
  final Map<String, dynamic> payload;
}

/// Outcome of pushing one queued op.
sealed class PushResult {
  const PushResult();

  /// Server accepted; local truth updated.
  static const PushResult applied = PushApplied();

  /// Terminal rejection (422/409/closed): adapter performed its compensating
  /// local write; op is removed from the queue.
  static const PushResult terminalFailure = PushTerminalFailure();

  /// Transient (429/5xx/offline): op stays queued, retried after backoff.
  static PushResult retryLater([Duration? retryAfter]) =>
      PushRetryLater(retryAfter);
}

final class PushApplied extends PushResult {
  const PushApplied();
}

final class PushTerminalFailure extends PushResult {
  const PushTerminalFailure();
}

final class PushRetryLater extends PushResult {
  const PushRetryLater([this.retryAfter]);
  final Duration? retryAfter;
}

/// A feature registers one adapter per entity type: how to push its queued
/// ops, how to apply pulled deltas, and which conflict policy governs it
/// (09 §4: one queue, one scheduler — no per-feature snowflake sync).
abstract interface class SyncAdapter {
  EntityType get entityType;
  ConflictPolicy get policy;

  /// Push one queued operation to the server (carrying its idempotency key).
  /// Terminal failures must perform their compensating local write BEFORE
  /// returning [PushResult.terminalFailure] — the UI never sees a silent
  /// disappearance (09 §3.4).
  Future<PushResult> push(PendingOperation op);

  /// Apply a page of delta records (upserts + tombstones) transactionally.
  Future<void> applyDelta(List<DeltaRecord> records);
}
