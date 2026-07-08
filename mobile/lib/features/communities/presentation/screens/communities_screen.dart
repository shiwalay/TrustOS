import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/ui/demo_feedback.dart';

/// Communities tab — micro business communities with verified-outcome
/// receipts front and center (docs/15 §10: guests are converted by
/// evidence, not room energy). Demo data; production reads
/// community-service via the BFF.
class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  static const _mine = [
    (
      'Mumbai Founders Circle',
      '148 members · Health 82',
      '₹4.6L settled this quarter · 23 intros → 14 meetings',
      'Member · Top 12% contributor',
    ),
  ];

  static const _suggested = [
    (
      'D2C Operators India',
      '312 members · Health 74',
      '₹11.2L settled this quarter · weekly teardown calls',
      'Kavya Nair and 2 others you know are members',
    ),
    (
      'Pune Manufacturing Network',
      '96 members · Health 79',
      '₹7.8L settled this quarter · strong vendor-match board',
      'Matches your ERP referral track record',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Communities')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          _label(theme, 'YOUR COMMUNITIES'),
          const SizedBox(height: EmberSpacing.xs),
          for (final c in _mine) _communityCard(context, c, joined: true),
          const SizedBox(height: EmberSpacing.lg),
          _label(theme, 'SUGGESTED FOR YOU'),
          const SizedBox(height: EmberSpacing.xs),
          for (final c in _suggested) _communityCard(context, c),
          const SizedBox(height: EmberSpacing.md),
          Card(
            child: ListTile(
              leading: Icon(Icons.add_circle_outline, color: gold),
              title: const Text('Start a community'),
              subtitle: const Text(
                'Bring your BNI chapter, alumni group, or industry circle',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDemoSnack(context,
                  'Community setup started — you’ll be the founding host.'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );

  Widget _communityCard(
    BuildContext context,
    (String, String, String, String) c, {
    bool joined = false,
  }) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;
    final (name, meta, receipts, social) = c;

    return Card(
      margin: const EdgeInsets.only(bottom: EmberSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(EmberSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(name, style: theme.textTheme.titleMedium),
                ),
                if (joined)
                  Icon(Icons.verified_outlined, color: gold, size: 18)
                else
                  OutlinedButton(
                    onPressed: () => showDemoSnack(
                        context, 'Request sent — the host will review it.'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      side: BorderSide(color: gold.withValues(alpha: 0.6)),
                      foregroundColor: gold,
                    ),
                    child: const Text('Request'),
                  ),
              ],
            ),
            const SizedBox(height: EmberSpacing.xxs),
            Text(meta, style: theme.textTheme.bodySmall),
            const SizedBox(height: EmberSpacing.xs),
            Text(
              receipts,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: EmberSpacing.xxs),
            Text(
              social,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
