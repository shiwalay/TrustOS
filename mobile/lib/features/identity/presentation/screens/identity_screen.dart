import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Identity & verification — the T0–T4 ladder (identity-service; PRD §4.1:
/// every tier unlocks capability, KYC only needed to receive money).
class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  static const _tiers = [
    ('T0', 'Account created', 'Email + device', true),
    ('T1', 'Phone verified', 'Unlocks communities & referrals', true),
    ('T2', 'Business verified', 'GST / domain — unlocks campaigns & '
        'publishing (5 min)', false),
    ('T3', 'Social verified', 'LinkedIn cross-check — higher routing '
        'priority', false),
    ('T4', 'KYC', 'Only needed to receive payouts', false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Identity & verification')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Text(
            'Verification is the identity component of your Trust Index '
            '(118/150). Each tier is optional — until you want what it '
            'unlocks.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.md),
          for (final (tier, title, detail, done) in _tiers)
            Card(
              margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: done
                      ? positive.withValues(alpha: 0.15)
                      : theme.colorScheme.surfaceContainerHighest,
                  foregroundColor: done
                      ? positive
                      : theme.colorScheme.onSurfaceVariant,
                  child: Text(tier,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600)),
                ),
                title: Text(title),
                subtitle: Text(detail),
                trailing: done
                    ? Icon(Icons.check_circle_outline, color: positive)
                    : (tier == 'T2'
                        ? FilledButton(
                            onPressed: () {},
                            style: FilledButton.styleFrom(
                              minimumSize: const Size(0, 36),
                              backgroundColor: gold,
                              foregroundColor:
                                  theme.colorScheme.onTertiary,
                            ),
                            child: const Text('Verify'),
                          )
                        : const Icon(Icons.lock_outline, size: 18)),
              ),
            ),
        ],
      ),
    );
  }
}
