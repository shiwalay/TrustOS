import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// My Deals — the pipeline of opportunities becoming money (deal-service:
/// intro → meeting → proposal → won; invoices verify outcomes). Demo data.
class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  static const _deals = [
    ('Nexa Logistics — ERP rollout', '₹2.4L', 'Proposal', 'via Vikram Rao'),
    ('Sunrise Clinic — patient CRM', '₹80k', 'Meeting', 'via Divya Krishnan'),
    ('Bloom D2C — growth audit', '₹35k', 'Won', 'via Kavya Nair'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('My Deals')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _stat(theme, 'Pipeline', '₹3.2L', gold),
                  _stat(theme, 'Won this quarter', '₹1.2L', positive),
                  _stat(theme, 'From referrals', '68%', gold),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Text(
            'OPEN & RECENT',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          for (final (title, value, stage, source) in _deals)
            Card(
              margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
              child: ListTile(
                title: Text(title),
                subtitle: Text(source),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: stage == 'Won' ? positive : gold,
                      ),
                    ),
                    Text(stage, style: theme.textTheme.bodySmall),
                  ],
                ),
              ),
            ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            'Won deals settle through the ledger — that is what moves your '
            'Trust Index and the Business League. Self-reported numbers '
            'move nothing.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, String label, String value, Color color) =>
      Column(
        children: [
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(color: color)),
          const SizedBox(height: EmberSpacing.xxs),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      );
}
