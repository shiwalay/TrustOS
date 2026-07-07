import 'dart:convert';

import '../../../../core/errors/app_exception.dart';
import '../../../../core/sync/conflict_policy.dart';
import '../../../../core/sync/pending_operation.dart';
import '../../../../core/sync/sync_adapter.dart';
import '../local/referral_local_source.dart';
import '../models/referral_dto_mapper.dart';
import '../remote/referral_remote_source.dart';

/// Registers the referral entity with the sync engine: op push + delta apply
/// + conflict policy (queueAndConfirm — money class, 09 §4.4).
///
/// Rollback path (09 §3.4): a terminal server rejection triggers the
/// compensating local write here — the UI never sees a silent disappearance.
class ReferralSyncAdapter implements SyncAdapter {
  ReferralSyncAdapter(this._local, this._remote, {this.onRejected});

  final ReferralLocalSource _local;
  final ReferralRemoteSource _remote;

  /// Notification hook (real impl: local push with deep link to the referral
  /// + l10n body `referral.rejected.<type>` — explanation-first).
  final void Function(String referralId, String problemType)? onRejected;

  @override
  EntityType get entityType => EntityType.referral;

  @override
  ConflictPolicy get policy => ConflictPolicy.queueAndConfirm;

  @override
  Future<PushResult> push(PendingOperation op) async {
    try {
      final dto = await _remote.submit(
        jsonDecode(op.payloadJson) as Map<String, dynamic>,
        idempotencyKey: op.idempotencyKey,
      );
      // Server confirmed our create: promote pending row to synced truth.
      await _local.upsertFromRemote([ReferralDtoMapper.fromJson(dto)]);
      return PushResult.applied;
    } on ApiProblemException catch (p) {
      if (p.isTerminal) {
        // 422 ineligible / 409 duplicate / campaign closed → ROLLBACK.
        await _local.markRejected(op.entityId, p.type);
        onRejected?.call(op.entityId, p.type);
        return PushResult.terminalFailure; // op removed from queue
      }
      return PushResult.retryLater(p.retryAfter); // 429/5xx → backoff, op stays
    } on AppException {
      return PushResult.retryLater(); // offline/timeout → op stays queued
    }
  }

  @override
  Future<void> applyDelta(List<DeltaRecord> records) async {
    final tombstoned = records.where((r) => r.isTombstone);
    for (final record in tombstoned) {
      await _local.deleteRow(record.entityId);
    }
    await _local.upsertFromRemote(
      records
          .where((r) => !r.isTombstone)
          .map(ReferralDtoMapper.fromDelta)
          .toList(),
    );
  }
}
