import '../entities/referral.dart';
import '../repositories/referral_repository.dart';

/// Reactive list read for one campaign (Drift-first, sync-refreshed).
class WatchCampaignReferrals {
  const WatchCampaignReferrals(this._repo);

  final ReferralRepository _repo;

  Stream<List<Referral>> call(String campaignId) =>
      _repo.watchByCampaign(campaignId);
}
