import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/referral.dart';
import '../../referrals_module.dart';

/// List controller: exposes `AsyncValue<List<Referral>>` fed by the Drift
/// watch stream (offline-first — pendingSync rows flow through instantly).
///
/// Hand-written StreamNotifier instead of `@riverpod` codegen — see
/// mobile/README.md deviations (same AsyncValue surface, no build_runner
/// dependency in presentation).
class ReferralListController
    extends FamilyStreamNotifier<List<Referral>, String> {
  @override
  Stream<List<Referral>> build(String arg) {
    final watchCampaignReferrals = ref.watch(watchCampaignReferralsProvider);
    return watchCampaignReferrals(arg);
  }

  /// Pull-to-refresh: force a delta pull (10-ux-design.md §7 freshness).
  Future<void> refresh() =>
      ref.read(referralRepositoryProvider).refresh(arg);
}

final referralListProvider = StreamNotifierProvider.family<
    ReferralListController, List<Referral>, String>(ReferralListController.new);
