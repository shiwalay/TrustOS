import 'package:equatable/equatable.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/failures.dart';
import '../../domain/repositories/referral_repository.dart';
import '../../referrals_module.dart';

/// Submit state: idle → (loading) → queued(referralId).
sealed class SubmitState extends Equatable {
  const SubmitState();

  const factory SubmitState.idle() = SubmitIdle;
  const factory SubmitState.queued(String referralId) = SubmitQueued;

  @override
  List<Object?> get props => [];
}

final class SubmitIdle extends SubmitState {
  const SubmitIdle();
}

final class SubmitQueued extends SubmitState {
  const SubmitQueued(this.referralId);
  final String referralId;

  @override
  List<Object?> get props => [referralId];
}

/// AsyncNotifier per 09-mobile-architecture.md §3.4.
///
/// Optimistic *UI*: the pendingSync row already flows into the list via the
/// Drift watch — it shows instantly with a "Pending" chip. The REWARD is
/// never shown as earned until server truth (queue-and-confirm, not
/// optimistic money).
class SubmitReferralController
    extends FamilyAsyncNotifier<SubmitState, String> {
  @override
  Future<SubmitState> build(String arg) async => const SubmitState.idle();

  Future<void> submit(SubmitReferralDraft draft) async {
    final submitReferral = ref.read(submitReferralProvider);

    state = const AsyncValue.loading();
    try {
      final referral = await submitReferral(draft);
      state = AsyncValue.data(SubmitState.queued(referral.id));
    } on ReferralFailure catch (f, st) {
      state = AsyncValue.error(f, st); // validation failed → nothing written
    }
  }
}

final submitReferralControllerProvider = AsyncNotifierProvider.family<
    SubmitReferralController, SubmitState, String>(SubmitReferralController.new);
