import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/ui/demo_feedback.dart';

/// My campaigns — the business-owner side of the referral marketplace
/// (referral-service; PRD §4.5). Demo data.
class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('My campaigns')),
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
                      Expanded(
                        child: Text(
                          'Refer a clinic — ₹500 per demo booked',
                          style: theme.textTheme.titleMedium,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: EmberSpacing.xs,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: positive.withValues(alpha: 0.12),
                          borderRadius:
                              BorderRadius.circular(EmberRadii.chip),
                        ),
                        child: Text('Live',
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: positive)),
                      ),
                    ],
                  ),
                  const SizedBox(height: EmberSpacing.sm),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _stat(theme, '11', 'referrals'),
                      _stat(theme, '4', 'qualified'),
                      _stat(theme, '3', 'converted'),
                      _stat(theme, '₹1,500', 'paid out', color: gold),
                    ],
                  ),
                  const SizedBox(height: EmberSpacing.sm),
                  Text(
                    'Quality 96% · trusted referrers only (Bronze+) · '
                    'closes in 20 days',
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
              leading: Icon(Icons.add_circle_outline, color: gold),
              title: const Text('Create a campaign'),
              subtitle: const Text(
                'AI drafts the offer, terms, and outreach from one sentence',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDemoSnack(
                context,
                'AI is drafting your campaign — answer 2 questions to publish.',
                icon: Icons.auto_awesome_outlined,
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          Text(
            'Commissions are held in escrow on conversion and released '
            'after the 14-day no-dispute window (BR-073).',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _stat(ThemeData theme, String value, String label, {Color? color}) =>
      Column(
        children: [
          Text(value,
              style: theme.textTheme.titleMedium?.copyWith(color: color)),
          Text(label, style: theme.textTheme.bodySmall),
        ],
      );
}
