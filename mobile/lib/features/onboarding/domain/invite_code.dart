/// Invitation codes — TrustOS is invitation-only (docs/15 §launch mechanic:
/// an invite IS a vouch; it seeds the invitee's first trust-graph edge and
/// stakes a slice of the inviter's vouch weight).
///
/// Format: TRUST-XXXX or TRUST-XXXX-XXXX (A–Z, 0–9). Validation here is
/// format-only; identity-service owns real redemption (single-use, expiry,
/// inviter lookup). Demo mode resolves a stub inviter locally.
library;

class InviteValidation {
  const InviteValidation._(this.normalized, this.inviterName, this.error);

  final String? normalized;
  final String? inviterName;
  final String? error;

  bool get isValid => normalized != null;
}

abstract final class InviteCode {
  static final _format = RegExp(r'^TRUST-[A-Z0-9]{4}(-[A-Z0-9]{2,6})?$');

  /// Demo-mode inviter directory; production resolves via identity-service.
  static const _demoInviters = {
    'TRUST-DEMO': 'Rohan Mehta · Gold member',
    'TRUST-RVK7-GOLD': 'Priya Sharma · Platinum member',
  };

  static InviteValidation validate(String raw) {
    final code = raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');
    if (code.isEmpty) {
      return const InviteValidation._(null, null, 'Enter your invitation code.');
    }
    if (code == 'TRUST-DEMO' || _format.hasMatch(code)) {
      return InviteValidation._(
        code,
        _demoInviters[code] ?? 'A verified member',
        null,
      );
    }
    return const InviteValidation._(
      null,
      null,
      'That does not look like a TrustOS code (TRUST-XXXX).',
    );
  }
}
