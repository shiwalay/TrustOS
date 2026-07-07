import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/demo/demo_providers.dart';
import '../../../../core/demo/demo_seed.dart';
import '../../../../core/design_system/components/trust_band_ring.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Home — the daily loop (10-ux-design.md W2): trust pulse + a *small*
/// attention queue (three actions beat thirty notifications — docs/15 §9).
/// Hydrates from the seeded Drift read models; production swaps the source
/// to the BFF with the same shapes.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final caution = isDark ? EmberColors.cautionDark : EmberColors.cautionLight;
    final attention = ref.watch(homeAttentionProvider);

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
                          '+8 this month — two settled referrals.',
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
          Text(
            'NEEDS YOUR ATTENTION',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          attention.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(EmberSpacing.lg),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (e, _) => Text('Could not load your feed: $e'),
            data: (data) {
              final quiet = data.quietContacts.take(2).toList();
              final campaigns = data.openCampaigns.take(2).toList();
              return Column(
                children: [
                  for (final c in quiet)
                    Card(
                      margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
                      child: ListTile(
                        leading:
                            Icon(Icons.nightlight_outlined, color: caution),
                        title: Text('${c.name} is going quiet'),
                        subtitle: Text(
                          '${c.daysSinceInteraction} days since you spoke · '
                          'strength ${c.relationshipStrength} — strong ties '
                          'fade quietly',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go(Routes.network),
                      ),
                    ),
                  if (data.pendingSyncCount > 0)
                    Card(
                      margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
                      child: ListTile(
                        leading: Icon(Icons.cloud_upload_outlined,
                            color: caution),
                        title: Text(
                          '${data.pendingSyncCount} referrals waiting to sync',
                        ),
                        subtitle: const Text(
                          'Queued offline — they send themselves when '
                          'you are back online',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.push(Routes
                            .campaignReferrals(DemoSeeder.campaignClinic)),
                      ),
                    ),
                  for (final cmp in campaigns)
                    Card(
                      margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
                      child: ListTile(
                        leading: Icon(
                          Icons.card_giftcard_outlined,
                          color: theme.colorScheme.tertiary,
                        ),
                        title: Text(cmp.title),
                        subtitle: Text(
                          cmp.expiresAt == null
                              ? 'Open campaign'
                              : 'Closes in ${cmp.expiresAt!.difference(DateTime.now().toUtc()).inDays} days',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () =>
                            context.push(Routes.campaignReferrals(cmp.id)),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}
