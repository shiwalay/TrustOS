import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/referrals/data/local/referral_dao.dart';
import '../../features/referrals/data/local/referral_table.dart';
import '../../features/referrals/domain/entities/referral.dart';
import '../sync/conflict_policy.dart';
import '../sync/pending_operation.dart';
import 'sync_tables.dart';

part 'app_database.g.dart';

/// App-wide Drift database (09-mobile-architecture.md core/storage).
///
/// NOTE — generated code: run `dart run build_runner build
/// --delete-conflicting-outputs` to produce `app_database.g.dart` (and DAO
/// mixins) before analyzing/building.
///
/// Production hardening deferred from this skeleton: SQLCipher encryption
/// with a hardware-wrapped key from the secure vault (09 §4.6/§5.3), and a
/// migrations/ folder with schema-snapshot tests (09 §8).
@DriftDatabase(
  tables: [
    PendingOperations,
    SyncCursors,
    ReferralRows,
    ReferralCampaignRows,
  ],
  daos: [ReferralDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Default on-device database.
  factory AppDatabase.open() =>
      AppDatabase(driftDatabase(name: 'trustos'));

  @override
  int get schemaVersion => 1;
}
