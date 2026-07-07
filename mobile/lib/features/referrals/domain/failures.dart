/// ReferralFailure — sealed failure taxonomy for the referrals slice
/// (09-mobile-architecture.md §2.1: network/validation/conflict/rejected).
sealed class ReferralFailure implements Exception {
  const ReferralFailure(this.code);

  /// Stable code; UI resolves user copy via l10n key `referral.failure.<code>`.
  final String code;

  const factory ReferralFailure.validation(String code) = ReferralValidationFailure;
  const factory ReferralFailure.network() = ReferralNetworkFailure;
  const factory ReferralFailure.conflict(String code) = ReferralConflictFailure;
  const factory ReferralFailure.rejected(String code) = ReferralRejectedFailure;

  @override
  String toString() => '$runtimeType($code)';
}

/// Client-side validation failed — nothing was written.
final class ReferralValidationFailure extends ReferralFailure {
  const ReferralValidationFailure(super.code);
}

final class ReferralNetworkFailure extends ReferralFailure {
  const ReferralNetworkFailure() : super('network');
}

/// e.g. duplicate prospect for this campaign (server 409).
final class ReferralConflictFailure extends ReferralFailure {
  const ReferralConflictFailure(super.code);
}

/// Terminal server rejection (ineligible, campaign closed).
final class ReferralRejectedFailure extends ReferralFailure {
  const ReferralRejectedFailure(super.code);
}
