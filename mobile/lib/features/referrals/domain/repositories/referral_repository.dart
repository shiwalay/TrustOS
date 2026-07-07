import '../entities/referral.dart';

/// Repository interface — 09-mobile-architecture.md §3.1. Pure domain: no
/// drift/dio imports; implemented in data/.
abstract interface class ReferralRepository {
  /// Reactive read: emits from Drift immediately, again after every sync apply.
  Stream<List<Referral>> watchByCampaign(String campaignId);

  /// Pull-to-refresh: force a delta pull for the referral entity type.
  Future<void> refresh(String campaignId);

  /// Queue-and-confirm submit (money-class op — never optimistic on reward).
  /// Returns the locally persisted pendingSync referral.
  Future<Referral> submit(SubmitReferralDraft draft);
}

class SubmitReferralDraft {
  const SubmitReferralDraft({
    required this.campaignId,
    required this.prospectName,
    required this.prospectPhone,
    required this.note,
    required this.consentConfirmed, // prospect consent checkbox — hard requirement
  });

  final String campaignId;
  final String prospectName;
  final String prospectPhone;
  final String note;
  final bool consentConfirmed;
}
