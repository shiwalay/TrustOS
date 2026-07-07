import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/di/providers.dart';
import 'data/local/referral_local_source.dart';
import 'data/referral_repository_impl.dart';
import 'data/remote/referral_remote_source.dart';
import 'data/sync/referral_sync_adapter.dart';
import 'domain/repositories/referral_repository.dart';
import 'domain/usecases/submit_referral.dart';
import 'domain/usecases/watch_campaign_referrals.dart';

/// Feature manifest (09-mobile-architecture.md §2.1): DI registrations +
/// sync-adapter registration for the referrals slice. Routes live in
/// app/router/routes.dart.

final referralLocalSourceProvider = Provider<ReferralLocalSource>(
  (ref) => ref.watch(databaseProvider).referralDao,
);

final referralRemoteSourceProvider = Provider<ReferralRemoteSource>(
  (ref) => ReferralRemoteSource(ref.watch(dioProvider)),
);

final referralSyncAdapterProvider = Provider<ReferralSyncAdapter>(
  (ref) => ReferralSyncAdapter(
    ref.watch(referralLocalSourceProvider),
    ref.watch(referralRemoteSourceProvider),
  ),
);

/// Registers the adapter with the engine. Read once from bootstrap (and
/// transitively by the repository) so registration precedes any sync call.
final referralsSyncRegistrationProvider = Provider<void>((ref) {
  ref.watch(syncEngineProvider).register(ref.watch(referralSyncAdapterProvider));
});

final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  ref.watch(referralsSyncRegistrationProvider);
  return ReferralRepositoryImpl(
    ref.watch(referralLocalSourceProvider),
    ref.watch(syncEngineProvider),
    ref.watch(clockProvider),
  );
});

// Use-cases (domain) exposed to presentation via DI.

final submitReferralProvider = Provider<SubmitReferral>(
  (ref) => SubmitReferral(ref.watch(referralRepositoryProvider)),
);

final watchCampaignReferralsProvider = Provider<WatchCampaignReferrals>(
  (ref) => WatchCampaignReferrals(ref.watch(referralRepositoryProvider)),
);
