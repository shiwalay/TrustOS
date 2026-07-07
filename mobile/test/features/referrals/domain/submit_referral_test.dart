import 'package:flutter_test/flutter_test.dart';
import 'package:trustos/features/referrals/domain/entities/referral.dart';
import 'package:trustos/features/referrals/domain/failures.dart';
import 'package:trustos/features/referrals/domain/repositories/referral_repository.dart';
import 'package:trustos/features/referrals/domain/usecases/submit_referral.dart';

class _FakeReferralRepository implements ReferralRepository {
  SubmitReferralDraft? submittedDraft;

  @override
  Stream<List<Referral>> watchByCampaign(String campaignId) =>
      const Stream.empty();

  @override
  Future<void> refresh(String campaignId) async {}

  @override
  Future<Referral> submit(SubmitReferralDraft draft) async {
    submittedDraft = draft;
    return Referral(
      id: 'ref_test',
      campaignId: draft.campaignId,
      prospectName: draft.prospectName,
      prospectPhone: draft.prospectPhone,
      note: draft.note,
      status: ReferralStatus.pendingSync,
      updatedAt: DateTime.utc(2026, 1, 1),
    );
  }
}

SubmitReferralDraft _draft({
  String name = 'Dev Patel',
  String phone = '+919876543210',
  bool consent = true,
}) =>
    SubmitReferralDraft(
      campaignId: 'cmp_1',
      prospectName: name,
      prospectPhone: phone,
      note: 'Runs a 40-person agency',
      consentConfirmed: consent,
    );

void main() {
  late _FakeReferralRepository repo;
  late SubmitReferral submitReferral;

  setUp(() {
    repo = _FakeReferralRepository();
    submitReferral = SubmitReferral(repo);
  });

  group('SubmitReferral validation (nothing written on failure)', () {
    test('rejects missing consent — hard gate', () async {
      await expectLater(
        () => submitReferral(_draft(consent: false)),
        throwsA(
          isA<ReferralValidationFailure>()
              .having((f) => f.code, 'code', 'consent_required'),
        ),
      );
      expect(repo.submittedDraft, isNull);
    });

    test('rejects prospect name shorter than 2 chars', () async {
      await expectLater(
        () => submitReferral(_draft(name: ' D ')),
        throwsA(
          isA<ReferralValidationFailure>()
              .having((f) => f.code, 'code', 'prospect_name_too_short'),
        ),
      );
      expect(repo.submittedDraft, isNull);
    });

    test('rejects non-E.164 phone', () async {
      await expectLater(
        () => submitReferral(_draft(phone: '98765')),
        throwsA(
          isA<ReferralValidationFailure>()
              .having((f) => f.code, 'code', 'invalid_phone'),
        ),
      );
      expect(repo.submittedDraft, isNull);
    });

    test('accepts E.164 phone with formatting characters', () async {
      final referral = await submitReferral(_draft(phone: '+91 98765-43210'));
      expect(referral.status, ReferralStatus.pendingSync);
      expect(repo.submittedDraft, isNotNull);
    });
  });

  group('Referral entity', () {
    final referral = Referral(
      id: 'ref_1',
      campaignId: 'cmp_1',
      prospectName: 'Dev',
      prospectPhone: '+919876543210',
      note: '',
      status: ReferralStatus.pendingSync,
      updatedAt: DateTime.utc(2026, 1, 1),
    );

    test('pendingSync is not settled locally', () {
      expect(referral.isSettledLocally, isFalse);
      expect(
        referral.copyWith(status: ReferralStatus.submitted).isSettledLocally,
        isTrue,
      );
    });

    test('reward is ledger-backed only from converted/settled', () {
      for (final status in ReferralStatus.values) {
        final expected = status == ReferralStatus.converted ||
            status == ReferralStatus.settled;
        expect(
          referral.copyWith(status: status).rewardIsLedgerBacked,
          expected,
          reason: 'status $status',
        );
      }
    });
  });
}
