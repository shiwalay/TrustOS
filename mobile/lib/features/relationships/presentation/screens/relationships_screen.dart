import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Relationship timeline — the deep view of one tie (relationship-service).
/// Demo: Rohan Mehta's timeline; production hydrates per-relationship from
/// the BFF with the AI relationship score (06 §2).
class RelationshipsScreen extends StatelessWidget {
  const RelationshipsScreen({super.key});

  static const _timeline = [
    ('Today', 'Copilot drafted a reconnect message — awaiting your edit',
        Icons.auto_awesome_outlined, false),
    ('44 days ago', 'Coffee at Blue Tokai, Bandra — intro to Deshmukh '
        'Realty discussed', Icons.local_cafe_outlined, true),
    ('3 months ago', 'He vouched for you (+2 trust)',
        Icons.workspace_premium_outlined, true),
    ('4 months ago', 'You referred Dr. Nisha Menon to his portfolio '
        'clinic — converted ₹500', Icons.card_giftcard_outlined, true),
    ('6 months ago', 'Met at BNI Mumbai West · imported from phone '
        'contacts', Icons.group_add_outlined, true),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final caution = isDark ? EmberColors.cautionDark : EmberColors.cautionLight;
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Relationship')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: gold.withValues(alpha: 0.15),
                    foregroundColor: gold,
                    child: const Text('RM'),
                  ),
                  const SizedBox(width: EmberSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Rohan Mehta',
                            style: theme.textTheme.titleMedium),
                        Text('Mehta Ventures · Finance · Mumbai',
                            style: theme.textTheme.bodySmall),
                        const SizedBox(height: EmberSpacing.xxs),
                        Text(
                          '44 days quiet — strong ties fade quietly',
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: caution),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    children: [
                      Text('92',
                          style: theme.textTheme.headlineMedium
                              ?.copyWith(color: gold)),
                      Text('strength', style: theme.textTheme.bodySmall),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.sm),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Send the reconnect draft'),
                ),
              ),
            ],
          ),
          const SizedBox(height: EmberSpacing.lg),
          Text(
            'TIMELINE',
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
                for (final (moment, what, icon, past) in _timeline)
                  ListTile(
                    leading: Icon(icon,
                        color: past
                            ? theme.colorScheme.onSurfaceVariant
                            : gold),
                    title: Text(what, style: theme.textTheme.bodyMedium),
                    subtitle: Text(moment),
                    dense: true,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
