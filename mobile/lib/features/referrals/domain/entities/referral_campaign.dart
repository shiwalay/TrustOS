import 'package:equatable/equatable.dart';

import 'money.dart';

/// Referral campaign terms — reward as [Money] (never floats), eligibility
/// summarized; full terms parsed lazily from the server payload.
class ReferralCampaign extends Equatable {
  const ReferralCampaign({
    required this.id, // 'cmp_…'
    required this.orgId, // 'org_…'
    required this.title,
    required this.rewardPerConversion,
    this.rewardPerQualification,
    this.expiresAt,
  });

  final String id;
  final String orgId;
  final String title;
  final Money rewardPerConversion;
  final Money? rewardPerQualification;
  final DateTime? expiresAt;

  bool isOpen(DateTime nowUtc) =>
      expiresAt == null || nowUtc.isBefore(expiresAt!);

  @override
  List<Object?> get props =>
      [id, orgId, title, rewardPerConversion, rewardPerQualification, expiresAt];
}
