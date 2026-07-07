import '../../domain/entities/referral.dart';

/// Server-confirmed referral state as applied to the local cache.
class ReferralUpsert {
  const ReferralUpsert({required this.referral, required this.serverVersion});

  final Referral referral;

  /// Per-row version from the delta feed — drives dirty-aware merge.
  final int serverVersion;
}

/// Local persistence boundary for referrals. The Drift DAO
/// ([referral_dao.dart]) is the production implementation; keeping the
/// repository and sync adapter on this interface makes both unit-testable
/// with an in-memory fake (09 §8 mocking rule).
abstract interface class ReferralLocalSource {
  /// Ordered by updatedAt desc; re-emits on every local/sync write.
  Stream<List<Referral>> watchByCampaign(String campaignId);

  /// Queue-and-confirm local half: row lands with syncState=pendingCreate
  /// and status=pendingSync.
  Future<void> insertPendingCreate(Referral referral);

  /// Delta-apply from server. Dirty-aware: a locally-pending row is never
  /// clobbered by an older server version; a newer server version promotes
  /// the pending row to synced truth (09 §3.2).
  Future<void> upsertFromRemote(List<ReferralUpsert> records);

  /// Compensating write for a terminal server rejection (09 §3.4).
  Future<void> markRejected(String id, String reasonType);

  Future<void> deleteRow(String id);
}
