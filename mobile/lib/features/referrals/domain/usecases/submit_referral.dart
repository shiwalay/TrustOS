import '../entities/e164.dart';
import '../entities/referral.dart';
import '../failures.dart';
import '../repositories/referral_repository.dart';

/// Validation + eligibility rules live HERE, not in the controller
/// (09-mobile-architecture.md §3.1).
class SubmitReferral {
  const SubmitReferral(this._repo);

  final ReferralRepository _repo;

  Future<Referral> call(SubmitReferralDraft draft) async {
    if (!draft.consentConfirmed) {
      throw const ReferralFailure.validation('consent_required');
    }
    if (draft.prospectName.trim().length < 2) {
      throw const ReferralFailure.validation('prospect_name_too_short');
    }
    final phone = E164.tryParse(draft.prospectPhone);
    if (phone == null) {
      throw const ReferralFailure.validation('invalid_phone');
    }
    // Eligibility (campaign open, user not self-referring) is re-validated
    // server-side; client validates for immediate feedback only.
    return _repo.submit(draft);
  }
}
