import 'package:drift/drift.dart';

import '../../features/referrals/data/local/referral_table.dart';
import '../../features/referrals/domain/entities/referral.dart';
import '../storage/app_database.dart';

/// Demo dataset for non-prod flavors: realistic Indian-business contacts,
/// referral campaigns, and referrals covering EVERY lifecycle state —
/// including two pendingSync rows so the offline queue-and-confirm UX
/// (10-ux-design.md §7 row-level truth) is visible without a backend.
///
/// Idempotent: seeds only when the campaigns table is empty.
abstract final class DemoSeeder {
  static const campaignClinic = 'cmp_0197d001000070008000000000000001';
  static const campaignCa = 'cmp_0197d001000070008000000000000002';
  static const campaignD2c = 'cmp_0197d001000070008000000000000003';

  static Future<void> seedIfEmpty(AppDatabase db) async {
    final existing = await (db.select(db.referralCampaignRows)
          ..limit(1))
        .get();
    if (existing.isNotEmpty) return;

    final now = DateTime.now().toUtc();

    await db.batch((batch) {
      batch.insertAll(db.referralCampaignRows, [
        ReferralCampaignRowsCompanion.insert(
          id: campaignClinic,
          title: 'Refer a clinic — ₹500 per demo booked',
          orgId: 'org_meddo',
          termsJson:
              '{"org":"Meddo Health","reward":{"minorUnits":50000,"currencyCode":"INR"},'
              '"qualified":"demo attended within 30d","payoutRate":"96%"}',
          expiresAt: Value(now.add(const Duration(days: 21))),
          updatedAt: now,
        ),
        ReferralCampaignRowsCompanion.insert(
          id: campaignCa,
          title: 'CA firm intro — 2% of first invoice',
          orgId: 'org_shah_associates',
          termsJson:
              '{"org":"Shah & Associates","reward":"2% of first invoice",'
              '"qualified":"discovery call held","payoutRate":"91%"}',
          expiresAt: Value(now.add(const Duration(days: 45))),
          updatedAt: now,
        ),
        ReferralCampaignRowsCompanion.insert(
          id: campaignD2c,
          title: 'Refer a D2C brand — ₹4,000 on conversion',
          orgId: 'org_acme_growth',
          termsJson:
              '{"org":"Acme Growth Studio","reward":{"minorUnits":400000,'
              '"currencyCode":"INR"},"qualified":"audit call attended"}',
          expiresAt: Value(now.add(const Duration(days: 14))),
          updatedAt: now,
        ),
      ]);

      batch.insertAll(db.referralRows, [
        // --- Clinic campaign: full lifecycle spread -------------------
        _referral('ref_d001', campaignClinic, 'Dr. Kavita Rane',
            '+919820011001', 'Runs a 2-branch dental clinic in Andheri',
            ReferralStatus.submitted, now, days: 1),
        _referral('ref_d002', campaignClinic, 'Dr. Sameer Kulkarni',
            '+919820011002', 'Pediatric clinic, asked about patient CRM',
            ReferralStatus.qualified, now, days: 4, rewardMinor: 50000),
        _referral('ref_d003', campaignClinic, 'Dr. Nisha Menon',
            '+919820011003', 'Physio chain, 3 centres in Pune',
            ReferralStatus.converted, now, days: 9, rewardMinor: 50000),
        _referral('ref_d004', campaignClinic, 'Dr. Arvind Shetty',
            '+919820011004', 'Diagnostics lab, met at BNI Mumbai',
            ReferralStatus.settled, now, days: 16, rewardMinor: 50000),
        _referral('ref_d005', campaignClinic, 'Dr. Farah Khan',
            '+919820011005', 'Skin clinic — already using a competitor',
            ReferralStatus.rejected, now, days: 12),
        _referral('ref_d006', campaignClinic, 'Dr. Prakash Iyer',
            '+919820011006', 'Never picked up after intro',
            ReferralStatus.expired, now, days: 34),
        // Offline rows: queued locally, not yet accepted by the server.
        _pending('ref_d007', campaignClinic, 'Dr. Meera Joshi',
            '+919820011007', 'ENT practice, wants demo next week', now),

        // --- CA campaign ----------------------------------------------
        _referral('ref_d008', campaignCa, 'Rakesh Agarwal',
            '+919820011008', '40-person logistics firm, GST mess',
            ReferralStatus.qualified, now, days: 3),
        _referral('ref_d009', campaignCa, 'Sunita Reddy',
            '+919820011009', 'Two D2C brands, needs audit + filings',
            ReferralStatus.converted, now, days: 11, rewardMinor: 1200000),
        _pending('ref_d010', campaignCa, 'Mohit Bansal',
            '+919820011010', 'Startup founder, funding round closing', now),

        // --- D2C campaign ---------------------------------------------
        _referral('ref_d011', campaignD2c, 'Ananya Iyer',
            '+919820011011', 'Ayurveda skincare brand on Shopify',
            ReferralStatus.submitted, now, days: 2),
      ]);

      batch.insertAll(db.contactRows, _contacts);
    });
  }

  static ReferralRowsCompanion _referral(
    String id,
    String campaignId,
    String name,
    String phone,
    String note,
    ReferralStatus status,
    DateTime now, {
    required int days,
    int? rewardMinor,
  }) =>
      ReferralRowsCompanion.insert(
        id: id,
        campaignId: campaignId,
        prospectName: name,
        prospectPhone: phone,
        note: Value(note),
        status: status,
        rewardMinorUnits: Value(rewardMinor),
        rewardCurrency: Value(rewardMinor == null ? null : 'INR'),
        updatedAt: now.subtract(Duration(days: days)),
        syncedAt: Value(now.subtract(Duration(days: days))),
        syncState: SyncState.synced,
        serverVersion: const Value(1),
      );

  static ReferralRowsCompanion _pending(
    String id,
    String campaignId,
    String name,
    String phone,
    String note,
    DateTime now,
  ) =>
      ReferralRowsCompanion.insert(
        id: id,
        campaignId: campaignId,
        prospectName: name,
        prospectPhone: phone,
        note: Value(note),
        status: ReferralStatus.pendingSync,
        updatedAt: now.subtract(const Duration(minutes: 20)),
        syncState: SyncState.pendingCreate,
      );

  static List<ContactRowsCompanion> get _contacts => [
        _contact('c01', 'Rohan Mehta', 'Mehta Ventures', 'Finance', 'Mumbai',
            strength: 92, days: 44, business: true),
        _contact('c02', 'Priya Sharma', 'Meridian Design', 'Design', 'Mumbai',
            strength: 84, days: 42, business: true),
        _contact('c03', 'Vikram Rao', 'Nexa Logistics', 'Logistics',
            'Bengaluru', strength: 78, days: 8, business: true),
        _contact('c04', 'Ananya Iyer', 'Angel investor', 'Investing',
            'Chennai', strength: 71, days: 15, business: true),
        _contact('c05', 'Manoj Kulkarni', 'PayLite Fintech', 'Fintech', 'Pune',
            strength: 69, days: 3, business: true),
        _contact('c06', 'Kavya Nair', 'Bloom D2C', 'E-commerce', 'Kochi',
            strength: 66, days: 21, business: true),
        _contact('c07', 'Dev Patel', 'Freelance designer', 'Design',
            'Ahmedabad', strength: 61, days: 5, business: false),
        _contact('c08', 'Sneha Rao', 'Rao & Co CA', 'Accounting', 'Hyderabad',
            strength: 58, days: 30, business: true),
        _contact('c09', 'Arjun Malhotra', 'GrowthLab Agency', 'Marketing',
            'Delhi', strength: 55, days: 12, business: true),
        _contact('c10', 'Farah Sheikh', 'Zaika Foods', 'F&B', 'Lucknow',
            strength: 52, days: 27, business: true),
        _contact('c11', 'Amit Deshmukh', 'Deshmukh Realty', 'Real estate',
            'Nagpur', strength: 47, days: 60, business: true),
        _contact('c12', 'Meera Joshi', 'HR consultant', 'HR', 'Mumbai',
            strength: 44, days: 18, business: false),
        _contact('c13', 'Rahul Verma', 'CloudPeak SaaS', 'SaaS', 'Bengaluru',
            strength: 41, days: 38, business: true),
        _contact('c14', 'Divya Krishnan', 'Sunrise Clinic', 'Healthcare',
            'Chennai', strength: 39, days: 51, business: true),
        _contact('c15', 'Karan Singh', 'Student — MBA', 'Education', 'Indore',
            strength: 25, days: 90, business: false),
      ];

  static ContactRowsCompanion _contact(
    String id,
    String name,
    String company,
    String industry,
    String city, {
    required int strength,
    required int days,
    required bool business,
  }) =>
      ContactRowsCompanion.insert(
        id: 'usr_demo_$id',
        name: name,
        company: company,
        industry: industry,
        city: city,
        phone: '+9198200$id'.replaceAll('c', '1'),
        relationshipStrength: Value(strength),
        daysSinceInteraction: Value(days),
        runsBusiness: Value(business),
      );
}
