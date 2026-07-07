import 'package:flutter_test/flutter_test.dart';
import 'package:trustos/features/onboarding/domain/invite_code.dart';

void main() {
  group('InviteCode.validate', () {
    test('accepts the demo code and resolves the demo inviter', () {
      final v = InviteCode.validate('trust-demo');
      expect(v.isValid, isTrue);
      expect(v.normalized, 'TRUST-DEMO');
      expect(v.inviterName, contains('Rohan Mehta'));
    });

    test('normalizes case and whitespace', () {
      final v = InviteCode.validate('  trust-rvk7-gold ');
      expect(v.isValid, isTrue);
      expect(v.normalized, 'TRUST-RVK7-GOLD');
    });

    test('accepts well-formed unknown codes with a generic inviter', () {
      final v = InviteCode.validate('TRUST-9XK2');
      expect(v.isValid, isTrue);
      expect(v.inviterName, 'A verified member');
    });

    test('rejects empty input with a prompt, not a scold', () {
      final v = InviteCode.validate('   ');
      expect(v.isValid, isFalse);
      expect(v.error, contains('Enter'));
    });

    test('rejects malformed codes', () {
      for (final bad in ['HELLO', 'TRUST-', 'TRUST-ab', 'REF-1234']) {
        expect(InviteCode.validate(bad).isValid, isFalse, reason: bad);
      }
    });
  });
}
