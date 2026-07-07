import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';

/// Rewards — XP (progression), coins (spendable, ledger-backed), badges
/// with provenance. The firewall is stated in-product: coins and XP never
/// touch the Trust Index (docs/06 §6). Demo data.
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  static const _badges = [
    ('First settled referral', Icons.card_giftcard_outlined),
    ('6-week contribution streak', Icons.local_fire_department_outlined),
    ('Community builder', Icons.groups_outlined),
    ('T1 verified', Icons.verified_user_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Rewards')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Level 7', style: theme.textTheme.headlineMedium),
                      const Spacer(),
                      Text(
                        '2,340 / 3,000 XP',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: EmberSpacing.sm),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: 2340 / 3000,
                      minHeight: 8,
                      backgroundColor:
                          theme.colorScheme.surfaceContainerHighest,
                      color: gold,
                    ),
                  ),
                  const SizedBox(height: EmberSpacing.xs),
                  Text(
                    '660 XP to Level 8 — XP comes from verified '
                    'contributions, never from tapping around.',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.sm),
          Card(
            child: ListTile(
              leading: Icon(Icons.token_outlined, color: gold),
              title: const Text('1,250 coins'),
              subtitle: const Text(
                'Spend on profile boosts and event passes. Coins never '
                'touch your Trust Index.',
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Text(
            'BADGES',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          Wrap(
            spacing: EmberSpacing.xs,
            runSpacing: EmberSpacing.xs,
            children: [
              for (final (label, icon) in _badges)
                Chip(
                  avatar: Icon(icon, size: 16, color: gold),
                  label: Text(label),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
