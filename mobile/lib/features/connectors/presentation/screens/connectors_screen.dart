import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/ui/demo_feedback.dart';

/// Trusted Connectors — Stage-2 positioning (docs/15 §7.3): people pay for
/// certainty, not introductions. Problem-first discovery ("Need a factory?"
/// → the person who reliably delivers), plus your own path to becoming the
/// connector for one problem. Status is EARNED from verified outcomes, never
/// claimed. Demo data; production reads networking-service connector scores.
class ConnectorsScreen extends StatelessWidget {
  const ConnectorsScreen({super.key});

  // (problem, domain, name, subtitle, proof, band)
  static const _connectors = [
    ('Need a factory?', 'Manufacturing', 'Vikram Rao',
        'Nexa Logistics · Bengaluru',
        '12 verified intros · 92% land rate · ₹2.4Cr facilitated', 'Gold'),
    ('Need investors?', 'Fundraising', 'Ananya Iyer',
        'Angel investor · Chennai',
        '8 verified intros · ₹14Cr raised through them', 'Platinum'),
    ('Need influencers?', 'Marketing', 'Arjun Malhotra',
        'GrowthLab Agency · Delhi',
        '15 verified intros · 88% land rate', 'Gold'),
    ('Need a CA?', 'Accounting', 'Sneha Rao', 'Rao & Co CA · Hyderabad',
        '9 verified intros · 100% land rate', 'Silver'),
    ('Need to hire?', 'Talent', 'Rahul Verma', 'CloudPeak SaaS · Bengaluru',
        '6 verified placements this year', 'Silver'),
  ];

  // (domain, status, detail, progress 0..1 | null when earned)
  static const _standing = [
    ('Healthcare intros', 'Verified Connector', '4 settled clinic intros · '
        '90% land rate', null),
    ('D2C growth', 'Emerging', '2 more settled intros to earn Verified', 0.6),
    ('Fintech', 'Emerging', '1 of 3 verified intros', 0.33),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;

    return Scaffold(
      appBar: AppBar(title: const Text('Trusted Connectors')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Text(
            'People pay for certainty, not introductions. Find the person who '
            'reliably solves a problem — or become that person for one.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.lg),
          _label(theme, 'FIND A CONNECTOR'),
          const SizedBox(height: EmberSpacing.xs),
          for (final c in _connectors) _ConnectorCard(data: c),
          const SizedBox(height: EmberSpacing.lg),
          _label(theme, 'YOUR CONNECTOR STANDING'),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Column(
                children: [
                  for (var i = 0; i < _standing.length; i++) ...[
                    _StandingRow(data: _standing[i]),
                    if (i != _standing.length - 1)
                      const Divider(height: EmberSpacing.lg),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            'Pick one problem. Close a few, verified. Own it — the AI then '
            'routes every matching ask to you first.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: accent, fontWeight: FontWeight.w600),
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
}

class _ConnectorCard extends StatelessWidget {
  const _ConnectorCard({required this.data});
  final (String, String, String, String, String, String) data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final (problem, domain, name, subtitle, proof, band) = data;
    final initials = name
        .split(' ')
        .where((s) => s.isNotEmpty)
        .take(2)
        .map((s) => s[0])
        .join();

    return Card(
      margin: const EdgeInsets.only(bottom: EmberSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(EmberSpacing.cardPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(problem, style: theme.textTheme.titleMedium),
            const SizedBox(height: EmberSpacing.sm),
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: accent.withValues(alpha: 0.12),
                  foregroundColor: accent,
                  child: Text(initials),
                ),
                const SizedBox(width: EmberSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name,
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      Text(subtitle, style: theme.textTheme.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: EmberSpacing.xs),
            Row(
              children: [
                Icon(Icons.verified_rounded, size: 15, color: positive),
                const SizedBox(width: 5),
                Flexible(
                  child: Text('Verified Connector · $domain · $band',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: positive, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: EmberSpacing.xxs),
            Text(proof,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: EmberSpacing.sm),
            FilledButton(
              onPressed: () => showDemoSnack(
                  context, 'Intro requested from $name — expect a reply today.',
                  icon: Icons.swap_horiz_outlined),
              child: const Text('Request a trusted intro'),
            ),
          ],
        ),
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  const _StandingRow({required this.data});
  final (String, String, String, double?) data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = theme.colorScheme.primary;
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final (domain, status, detail, progress) = data;
    final earned = progress == null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(domain,
                  style: theme.textTheme.bodyLarge
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: EmberSpacing.xs, vertical: 3),
              decoration: BoxDecoration(
                color: (earned ? positive : accent).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(EmberRadii.chip),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(earned ? Icons.verified_rounded : Icons.trending_up_rounded,
                      size: 13, color: earned ? positive : accent),
                  const SizedBox(width: 4),
                  Text(status,
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: earned ? positive : accent,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: EmberSpacing.xxs),
        Text(detail,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        if (!earned) ...[
          const SizedBox(height: EmberSpacing.xs),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: accent,
            ),
          ),
        ],
      ],
    );
  }
}
