import '../../../../core/sync/sync_adapter.dart';
import '../../domain/entities/money.dart';
import '../../domain/entities/referral.dart';
import '../../domain/repositories/referral_repository.dart';
import '../local/referral_local_source.dart';

/// SDK DTO ↔ entity. DTOs (raw JSON until the generated `trustos_api` SDK
/// lands) never cross this line into domain/presentation (09 §2.1).
/// JSON is camelCase per _shared-context.md §5 naming.
abstract final class ReferralDtoMapper {
  static Map<String, dynamic> toCreateRequest(
    Referral referral,
    SubmitReferralDraft draft,
  ) =>
      {
        'id': referral.id, // client UUIDv7, server-honored
        'campaignId': referral.campaignId,
        'prospectName': referral.prospectName,
        'prospectPhone': referral.prospectPhone,
        'note': referral.note,
        'consentConfirmed': draft.consentConfirmed,
      };

  static ReferralUpsert fromJson(Map<String, dynamic> json) {
    final rewardJson = json['rewardEstimate'] as Map<String, dynamic>?;
    return ReferralUpsert(
      referral: Referral(
        id: json['id'] as String,
        campaignId: json['campaignId'] as String,
        prospectName: json['prospectName'] as String,
        prospectPhone: json['prospectPhone'] as String,
        note: json['note'] as String? ?? '',
        status: _statusFromWire(json['status'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String).toUtc(),
        rewardEstimate: rewardJson == null
            ? null
            : Money(
                minorUnits: rewardJson['minorUnits'] as int,
                currencyCode: rewardJson['currencyCode'] as String,
              ),
      ),
      serverVersion: json['version'] as int? ?? 0,
    );
  }

  static ReferralUpsert fromDelta(DeltaRecord record) =>
      fromJson({'id': record.entityId, ...record.payload, 'version': record.serverVersion});

  static ReferralStatus _statusFromWire(String wire) =>
      ReferralStatus.values.firstWhere(
        (s) => s.name == wire,
        orElse: () => ReferralStatus.submitted,
      );
}
