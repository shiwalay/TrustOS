import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';

/// Business League — percentile-band UX (10-ux-design.md W12: "Top 12%",
/// never "#1,009"), only ledger-verified value scores. Demo data; production
/// reads leaderboard-service snapshots.
class LeaderboardsScreen extends StatelessWidget {
  const LeaderboardsScreen({super.key});

  static const _top = [
    (1, 'Priya Sharma', 'Meridian Design', '₹4.2L'),
    (2, 'Vikram Rao', 'Nexa Logistics', '₹3.8L'),
    (3, 'Rohan Mehta', 'Mehta Ventures', '₹3.1L'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Business League')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Card(
            child: Container(
              padding: const EdgeInsets.all(EmberSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EmberRadii.card),
                border: Border.all(color: gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text('YOUR STANDING · JULY · MUMBAI',
                      style: theme.textTheme.bodySmall?.copyWith(
                        letterSpacing: 1.4,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      )),
                  const SizedBox(height: EmberSpacing.sm),
                  Text('Top 12%',
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: gold)),
                  const SizedBox(height: EmberSpacing.xxs),
                  Text(
                    '₹1.9L verified business created · ↑ from Top 18% in June',
                    style: theme.textTheme.bodyMedium,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Text(
            'THIS MONTH · VERIFIED BUSINESS GENERATED',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Column(
              children: [
                for (final (rank, name, org, value) in _top)
                  ListTile(
                    leading: CircleAvatar(
                      backgroundColor: gold.withValues(alpha: 0.15),
                      foregroundColor: gold,
                      child: Text('$rank'),
                    ),
                    title: Text(name),
                    subtitle: Text(org),
                    trailing: Text(
                      value,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(color: gold),
                    ),
                  ),
                const Divider(height: 1),
                ListTile(
                  tileColor: gold.withValues(alpha: 0.08),
                  leading: CircleAvatar(
                    backgroundColor: gold.withValues(alpha: 0.2),
                    foregroundColor: gold,
                    child: const Icon(Icons.person_outline, size: 18),
                  ),
                  title: const Text('You'),
                  subtitle: const Text('Top 12% band'),
                  trailing: Text(
                    '₹1.9L',
                    style:
                        theme.textTheme.titleMedium?.copyWith(color: gold),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            'Only ledger-verified value counts — activity scores nothing. '
            'Beyond the top three, you compete with your percentile band, '
            'not a demoralizing raw rank.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
