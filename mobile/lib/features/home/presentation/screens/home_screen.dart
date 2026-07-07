import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/design_system/components/trust_band_ring.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Home — the daily loop (10-ux-design.md W2: pulse + digest + attention
/// queue, BFF-fed). Skeleton: static sections + a working path into the
/// referrals vertical slice; real cards hydrate from Drift projections in a
/// later milestone.
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('TrustOS')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Row(
                children: [
                  const TrustBandRing(score: 712, size: 96),
                  const SizedBox(width: EmberSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Your Digital Trust Index',
                            style: theme.textTheme.titleMedium),
                        const SizedBox(height: EmberSpacing.xxs),
                        Text(
                          'Sample data — hydrates from trust-service after sync.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: EmberSpacing.xs),
                        TextButton(
                          onPressed: () => context.go(Routes.trustProfile),
                          child: const Text('See what builds your score'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          Text('NEEDS YOUR ATTENTION', style: theme.textTheme.bodySmall),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: ListTile(
              leading: const Icon(Icons.card_giftcard_outlined),
              title: const Text('Demo referral campaign'),
              subtitle: const Text('Try the offline-first submit flow'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  context.push(Routes.campaignReferrals(Routes.demoCampaignId)),
            ),
          ),
        ],
      ),
    );
  }
}
