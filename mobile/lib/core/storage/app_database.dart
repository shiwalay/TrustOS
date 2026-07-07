import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

import '../../features/contacts/data/local/contact_table.dart';
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
    ContactRows,
  ],
  daos: [ReferralDao],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  /// Default database. On the web this uses the drift WASM setup: both
  /// `sqlite3.wasm` and `drift_worker.js` are shipped in `web/` (see
  /// https://drift.simonbinder.eu/platforms/web/).
  factory AppDatabase.open() => AppDatabase(
        driftDatabase(
          name: 'trustos',
          web: DriftWebOptions(
            sqlite3Wasm: Uri.parse('sqlite3.wasm'),
            driftWorker: Uri.parse('drift_worker.js'),
          ),
        ),
      );

  @override
  int get schemaVersion => 1;
}
