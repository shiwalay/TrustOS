import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import '../../features/referrals/data/local/referral_table.dart';
import '../storage/app_database.dart';

/// Read-model providers over the seeded demo data (contacts, campaigns,
/// referrals). The real Home feed is BFF-fed (docs/09 §1); these providers
/// keep the same shape so swapping the source is contained.

enum InsightKind { network, reconnect, earn }

class AhaInsight {
  const AhaInsight({
    required this.kind,
    required this.title,
    required this.body,
  });

  final InsightKind kind;
  final String title;
  final String body;
}

final demoContactCountProvider = FutureProvider<int>((ref) async {
  final db = ref.watch(databaseProvider);
  final count = db.contactRows.id.count();
  final query = db.selectOnly(db.contactRows)..addColumns([count]);
  final row = await query.getSingle();
  return row.read(count) ?? 0;
});

/// The three onboarding reveal cards (10-ux-design.md §5.1: THE REVEAL —
/// insights about the user's own network, not generic marketing).
final ahaInsightsProvider = FutureProvider<List<AhaInsight>>((ref) async {
  final db = ref.watch(databaseProvider);
  final contacts = await db.select(db.contactRows).get();
  final campaigns = await db.select(db.referralCampaignRows).get();

  if (contacts.isEmpty) return _fallbackInsights(campaigns.length);

  final businesses = contacts.where((c) => c.runsBusiness).toList();
  final industryCounts = <String, int>{};
  for (final c in businesses) {
    industryCounts.update(c.industry, (v) => v + 1, ifAbsent: () => 1);
  }
  final topIndustry = industryCounts.entries.toList()
    ..sort((a, b) => b.value.compareTo(a.value));

  final quiet = contacts.where((c) => c.daysSinceInteraction >= 30).toList()
    ..sort((a, b) => b.relationshipStrength.compareTo(a.relationshipStrength));

  return [
    AhaInsight(
      kind: InsightKind.network,
      title: '${businesses.length} of your contacts run businesses',
      body: topIndustry.isEmpty
          ? 'Your network is broader than you think.'
          : '${topIndustry.first.value} in ${topIndustry.first.key} alone — '
              'your network is an asset.',
    ),
    if (quiet.isNotEmpty)
      AhaInsight(
        kind: InsightKind.reconnect,
        title: '${quiet.first.name} is your strongest tie — reconnect?',
        body: 'No interaction in ${quiet.first.daysSinceInteraction} days. '
            'Strong ties fade quietly.',
      ),
    AhaInsight(
      kind: InsightKind.earn,
      title: 'You could earn from ${campaigns.length} open referral campaigns',
      body: 'Businesses are paying for warm introductions you can '
          'already make.',
    ),
  ];
});

class HomeAttention {
  const HomeAttention({
    required this.quietContacts,
    required this.openCampaigns,
    required this.pendingSyncCount,
  });

  final List<ContactRow> quietContacts;
  final List<ReferralCampaignRow> openCampaigns;
  final int pendingSyncCount;
}

final homeAttentionProvider = FutureProvider<HomeAttention>((ref) async {
  final db = ref.watch(databaseProvider);

  final quiet = await (db.select(db.contactRows)
        ..where((c) => c.daysSinceInteraction.isBiggerOrEqualValue(30))
        ..orderBy([(c) => OrderingTerm.desc(c.relationshipStrength)])
        ..limit(3))
      .get();

  final campaigns = await (db.select(db.referralCampaignRows)
        ..orderBy([(c) => OrderingTerm.asc(c.expiresAt)]))
      .get();

  final pendingCount = db.referralRows.id.count();
  final pendingQuery = db.selectOnly(db.referralRows)
    ..addColumns([pendingCount])
    ..where(db.referralRows.syncState.equalsValue(SyncState.pendingCreate));
  final pendingRow = await pendingQuery.getSingle();

  return HomeAttention(
    quietContacts: quiet,
    openCampaigns: campaigns,
    pendingSyncCount: pendingRow.read(pendingCount) ?? 0,
  );
});

List<AhaInsight> _fallbackInsights(int campaignCount) => [
      const AhaInsight(
        kind: InsightKind.network,
        title: 'Your network is your net worth',
        body: 'Import contacts anytime from Network to see who runs '
            'businesses around you.',
      ),
      const AhaInsight(
        kind: InsightKind.reconnect,
        title: 'Strong ties fade quietly',
        body: 'TrustOS watches for relationships going quiet and nudges '
            'you before they do.',
      ),
      AhaInsight(
        kind: InsightKind.earn,
        title: campaignCount > 0
            ? 'You could earn from $campaignCount open referral campaigns'
            : 'Referral campaigns pay for warm intros',
        body: 'Businesses are paying for introductions you can already make.',
      ),
    ];
