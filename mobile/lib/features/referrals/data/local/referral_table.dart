import 'package:drift/drift.dart';

import '../../domain/entities/referral.dart';

/// Row-level sync bookkeeping (09-mobile-architecture.md §3.2).
enum SyncState { synced, dirty, pendingCreate, conflict }

@TableIndex(name: 'idx_referral_campaign', columns: {#campaignId, #updatedAt})
class ReferralRows extends Table {
  TextColumn get id => text()(); //                       ref_… UUIDv7
  TextColumn get campaignId => text()();
  TextColumn get prospectName => text()();
  TextColumn get prospectPhone => text()(); //            DB encrypted at rest (§4.6)
  TextColumn get note => text().withDefault(const Constant(''))();
  TextColumn get status => textEnum<ReferralStatus>()();
  IntColumn get rewardMinorUnits => integer().nullable()();
  TextColumn get rewardCurrency => text().nullable()(); // ISO 4217
  DateTimeColumn get updatedAt => dateTime()(); //        server timestamp when synced
  DateTimeColumn get syncedAt => dateTime().nullable()();
  TextColumn get syncState => textEnum<SyncState>()();
  IntColumn get serverVersion =>
      integer().withDefault(const Constant(0))(); // per-row version from delta feed

  @override
  Set<Column<Object>> get primaryKey => {id};
}

class ReferralCampaignRows extends Table {
  TextColumn get id => text()(); // cmp_…
  TextColumn get title => text()();
  TextColumn get orgId => text()();
  TextColumn get termsJson => text()(); // reward tiers, eligibility — parsed lazily
  DateTimeColumn get expiresAt => dateTime().nullable()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get serverVersion => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}
