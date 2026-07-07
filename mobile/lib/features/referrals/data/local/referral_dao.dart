import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/referral.dart';
import '../models/referral_row_mapper.dart';
import 'referral_local_source.dart';
import 'referral_table.dart';

part 'referral_dao.g.dart';

/// Drift DAO — production [ReferralLocalSource]. Requires
/// `dart run build_runner build` (generates `referral_dao.g.dart` +
/// `app_database.g.dart`).
@DriftAccessor(tables: [ReferralRows])
class ReferralDao extends DatabaseAccessor<AppDatabase>
    with _$ReferralDaoMixin
    implements ReferralLocalSource {
  ReferralDao(super.db);

  @override
  Stream<List<Referral>> watchByCampaign(String campaignId) =>
      (select(referralRows)
            ..where((t) => t.campaignId.equals(campaignId))
            ..orderBy([(t) => OrderingTerm.desc(t.updatedAt)]))
          .watch()
          .map((rows) => rows.map(ReferralRowMapper.toEntity).toList());

  @override
  Future<void> insertPendingCreate(Referral referral) =>
      into(referralRows).insert(ReferralRowMapper.toPendingCompanion(referral));

  /// Delta-apply from server. Dirty-aware: a locally-pending row is never
  /// clobbered by an older server version (queue-and-confirm, 09 §4.4).
  @override
  Future<void> upsertFromRemote(List<ReferralUpsert> records) =>
      transaction(() async {
        for (final record in records) {
          final existing = await (select(referralRows)
                ..where((t) => t.id.equals(record.referral.id)))
              .getSingleOrNull();
          final serverIsNewer =
              existing == null || record.serverVersion > existing.serverVersion;
          // Stale deltas never clobber local rows — in particular a
          // pendingCreate row survives until the server version that
          // confirms it arrives, which promotes it to synced truth here.
          if (!serverIsNewer) continue;
          await into(referralRows).insertOnConflictUpdate(
            ReferralRowMapper.toRemoteCompanion(
              record.referral,
              record.serverVersion,
            ),
          );
        }
      });

  @override
  Future<void> markRejected(String id, String reasonType) =>
      (update(referralRows)..where((t) => t.id.equals(id))).write(
        const ReferralRowsCompanion(
          status: Value(ReferralStatus.rejected),
          syncState: Value(SyncState.synced),
        ),
      );

  @override
  Future<void> deleteRow(String id) =>
      (delete(referralRows)..where((t) => t.id.equals(id))).go();
}
