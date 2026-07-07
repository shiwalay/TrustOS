import 'package:flutter/material.dart';

import '../../../../core/design_system/components/trust_band_ring.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Trust profile — explanation-first (10-ux-design.md W5): the DTI ring,
/// every component with its points, and recent movements with causes.
/// Demo data mirrors _shared-context.md §4 weights; production hydrates
/// from trust-service's factor ledger.
class TrustProfileScreen extends StatelessWidget {
  const TrustProfileScreen({super.key});

  static const _components = [
    ('Referral & opportunity performance', 152, 200),
    ('Identity & verification', 118, 150),
    ('Relationship quality', 121, 150),
    ('Transactions & deals', 96, 150),
    ('Community contribution', 64, 100),
    ('Consistency & longevity', 78, 100),
    ('Knowledge contribution', 28, 50),
    ('Peer vouches', 33, 50),
    ('AI confidence', 22, 50),
  ];

  static const _movements = [
    ('+6', 'Referral settled — Dr. Arvind Shetty (Meddo Health)', true),
    ('+2', 'New vouch from Priya Sharma', true),
    ('−3', 'Consistency decay — 2 quiet weeks', false),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final caution = isDark ? EmberColors.cautionDark : EmberColors.cautionLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Your Trust')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          const Center(
            child: TrustBandRing(
              score: 712,
              size: 148,
              semanticsLabel: 'Your Digital Trust Index',
            ),
          ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            'Every point traces to a verified fact. Nothing here can be '
            'bought — and anything can be appealed.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EmberSpacing.lg),
          _sectionLabel(theme, 'HOW YOUR 712 IS BUILT'),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Column(
                children: [
                  for (final (label, points, max) in _components) ...[
                    Row(
                      children: [
                        Expanded(
                          child:
                              Text(label, style: theme.textTheme.bodyMedium),
                        ),
                        Text(
                          '$points / $max',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.tertiary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: EmberSpacing.xxs),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: points / max,
                        minHeight: 5,
                        backgroundColor:
                            theme.colorScheme.surfaceContainerHighest,
                        color: theme.colorScheme.tertiary,
                      ),
                    ),
                    const SizedBox(height: EmberSpacing.sm),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          _sectionLabel(theme, 'RECENT MOVEMENTS'),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Column(
              children: [
                for (final (delta, cause, up) in _movements)
                  ListTile(
                    dense: true,
                    leading: Text(
                      delta,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: up ? positive : caution),
                    ),
                    title: Text(cause, style: theme.textTheme.bodyMedium),
                  ),
              ],
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          TextButton(
            onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Review requested — a human looks at every appeal.',
                ),
              ),
            ),
            child: const Text('Something looks wrong? Request a review'),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
}
