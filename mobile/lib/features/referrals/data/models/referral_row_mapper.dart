import 'package:drift/drift.dart';

import '../../../../core/storage/app_database.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/referral.dart';
import '../local/referral_table.dart';

/// Drift row ↔ entity (09-mobile-architecture.md §2.1). Row/Companion types
/// come from build_runner output (`app_database.g.dart`).
abstract final class ReferralRowMapper {
  static Referral toEntity(ReferralRow row) => Referral(
        id: row.id,
        campaignId: row.campaignId,
        prospectName: row.prospectName,
        prospectPhone: row.prospectPhone,
        note: row.note,
        // A locally-pending create always renders as pendingSync, whatever
        // status the payload carried (row-level truth — 10-ux-design.md §7).
        status: row.syncState == SyncState.pendingCreate
            ? ReferralStatus.pendingSync
            : row.status,
        updatedAt: row.updatedAt,
        rewardEstimate: row.rewardMinorUnits == null || row.rewardCurrency == null
            ? null
            : Money(
                minorUnits: row.rewardMinorUnits!,
                currencyCode: row.rewardCurrency!,
              ),
      );

  static ReferralRowsCompanion toPendingCompanion(Referral referral) =>
      ReferralRowsCompanion(
        id: Value(referral.id),
        campaignId: Value(referral.campaignId),
        prospectName: Value(referral.prospectName),
        prospectPhone: Value(referral.prospectPhone),
        note: Value(referral.note),
        status: Value(ReferralStatus.pendingSync),
        updatedAt: Value(referral.updatedAt),
        syncState: const Value(SyncState.pendingCreate),
        serverVersion: const Value(0),
      );

  static ReferralRowsCompanion toRemoteCompanion(
    Referral referral,
    int serverVersion,
  ) =>
      ReferralRowsCompanion(
        id: Value(referral.id),
        campaignId: Value(referral.campaignId),
        prospectName: Value(referral.prospectName),
        prospectPhone: Value(referral.prospectPhone),
        note: Value(referral.note),
        status: Value(referral.status),
        rewardMinorUnits: Value(referral.rewardEstimate?.minorUnits),
        rewardCurrency: Value(referral.rewardEstimate?.currencyCode),
        updatedAt: Value(referral.updatedAt),
        syncedAt: Value(DateTime.now().toUtc()),
        syncState: const Value(SyncState.synced),
        serverVersion: Value(serverVersion),
      );
}
