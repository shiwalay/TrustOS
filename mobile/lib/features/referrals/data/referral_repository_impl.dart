import 'dart:async';
import 'dart:convert';

import '../../../core/sync/conflict_policy.dart';
import '../../../core/sync/pending_operation.dart';
import '../../../core/sync/sync_adapter.dart';
import '../../../core/sync/sync_engine.dart';
import '../../../core/sync/trustos_id.dart';
import '../domain/entities/referral.dart';
import '../domain/repositories/referral_repository.dart';
import 'local/referral_local_source.dart';
import 'models/referral_dto_mapper.dart';

/// Offline-first read-through repository (09-mobile-architecture.md §3.3).
class ReferralRepositoryImpl implements ReferralRepository {
  ReferralRepositoryImpl(this._local, this._syncEngine, this._clock);

  final ReferralLocalSource _local;
  final SyncEngine _syncEngine;
  final Clock _clock;

  @override
  Stream<List<Referral>> watchByCampaign(String campaignId) {
    // 1. Emit local immediately (cold start renders in one frame from Drift).
    // 2. Kick a background delta pull; new data re-emits via the watch().
    unawaited(_syncEngine.requestPull(EntityType.referral, scope: campaignId));
    return _local.watchByCampaign(campaignId);
  }

  @override
  Future<void> refresh(String campaignId) =>
      _syncEngine.pullNow(EntityType.referral, scope: campaignId);

  @override
  Future<Referral> submit(SubmitReferralDraft draft) async {
    final id = TrustosId.generate('ref'); // client UUIDv7 → server honors it
    final now = _clock.nowUtc();
    final referral = Referral(
      id: id,
      campaignId: draft.campaignId,
      prospectName: draft.prospectName.trim(),
      prospectPhone: draft.prospectPhone,
      note: draft.note,
      status: ReferralStatus.pendingSync,
      updatedAt: now,
    );

    // Single transaction: local row + queued operation. Either both exist
    // or neither. NEVER optimistic on money (queueAndConfirm, 09 §4.4).
    await _syncEngine.enqueueWithLocalWrite(
      operation: PendingOperation(
        id: id, //                op id == entity id for creates
        entityType: EntityType.referral.wire,
        entityId: id,
        opType: OpType.create,
        idempotencyKey: id, //    replay-safe on retries (shared-context §5)
        payloadJson:
            jsonEncode(ReferralDtoMapper.toCreateRequest(referral, draft)),
        conflictPolicy: ConflictPolicy.queueAndConfirm,
        createdAt: now,
        nextAttemptAt: now,
      ),
      localWrite: () => _local.insertPendingCreate(referral),
    );
    return referral;
  }
}
