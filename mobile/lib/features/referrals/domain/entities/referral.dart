import 'package:equatable/equatable.dart';

import 'money.dart';

/// Referral lifecycle. Matches the referral-service state machine
/// (_shared-context.md §3 events): submitted → qualified → converted →
/// settled, with rejected/expired as terminal branches.
///
/// `pendingSync` is CLIENT-ONLY: the row exists locally but has not been
/// accepted by referral-service yet (queue-and-confirm — 09 §4.4). Note:
/// 09-mobile-architecture.md's exemplar enum omits `settled`; it is included
/// here because `referral.commission.settled.v1` is a canonical event and the
/// task's backend state machine requires it.
enum ReferralStatus {
  pendingSync, // exists locally, not yet accepted by referral-service
  submitted, //   server-acknowledged (ref_ id confirmed)
  qualified, //   referral.referral.qualified.v1 received
  converted, //   referral.referral.converted.v1 — reward now ledger-backed
  settled, //     referral.commission.settled.v1 — money moved
  rejected,
  expired,
}

class Referral extends Equatable {
  const Referral({
    required this.id, //         'ref_' + UUIDv7 (client-generated, server-honored)
    required this.campaignId, // 'cmp_…'
    required this.prospectName,
    required this.prospectPhone, // E.164; PII — DB encrypted at rest (09 §4.6)
    required this.note,
    required this.status,
    required this.updatedAt,
    this.rewardEstimate, // Money? — display only; truth comes from ledger-service
  });

  final String id;
  final String campaignId;
  final String prospectName;
  final String prospectPhone;
  final String note;
  final ReferralStatus status;
  final DateTime updatedAt; // UTC always (_shared-context.md §1)
  final Money? rewardEstimate;

  bool get isSettledLocally => status != ReferralStatus.pendingSync;

  /// Reward may render as earned ONLY from ledger-backed states (10-ux W15).
  bool get rewardIsLedgerBacked =>
      status == ReferralStatus.converted || status == ReferralStatus.settled;

  Referral copyWith({
    ReferralStatus? status,
    DateTime? updatedAt,
    Money? rewardEstimate,
  }) =>
      Referral(
        id: id,
        campaignId: campaignId,
        prospectName: prospectName,
        prospectPhone: prospectPhone,
        note: note,
        status: status ?? this.status,
        updatedAt: updatedAt ?? this.updatedAt,
        rewardEstimate: rewardEstimate ?? this.rewardEstimate,
      );

  @override
  List<Object?> get props => [id, campaignId, status, updatedAt, rewardEstimate];
}
