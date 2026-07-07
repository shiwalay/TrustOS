import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/tokens/spacing.dart';
import '../controllers/referral_list_controller.dart';
import '../widgets/referral_list_tile.dart';
import 'submit_referral_sheet.dart';

/// My Referrals (10-ux-design.md screen #19): status tracking with
/// loading/empty/error/data states per §7 state standards. PendingSync rows
/// arrive through the same Drift watch and are visibly marked "Pending sync".
class MyReferralsScreen extends ConsumerWidget {
  const MyReferralsScreen({required this.campaignId, super.key});

  final String campaignId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final referrals = ref.watch(referralListProvider(campaignId));

    return Scaffold(
      appBar: AppBar(title: const Text('My referrals')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showSubmitReferralSheet(context, campaignId),
        icon: const Icon(Icons.card_giftcard_outlined),
        label: const Text('Submit referral'),
      ),
      body: referrals.when(
        loading: () => const ReferralListSkeleton(),
        error: (e, _) => _ErrorState(
          onRetry: () =>
              ref.read(referralListProvider(campaignId).notifier).refresh(),
        ),
        data: (items) => items.isEmpty
            ? const _EmptyState()
            : RefreshIndicator(
                onRefresh: () => ref
                    .read(referralListProvider(campaignId).notifier)
                    .refresh(),
                child: ListView.builder(
                  itemExtent: 88, // fixed extent: 09 §6 scrolling budget
                  itemCount: items.length,
                  itemBuilder: (_, i) => ReferralListTile(items[i]),
                ),
              ),
      ),
    );
  }
}

/// Skeleton shaped like the real tiles (10-ux-design.md §7 skeleton policy;
/// the shared SkeletonBox component lands with the design_system package).
class ReferralListSkeleton extends StatelessWidget {
  const ReferralListSkeleton({super.key});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.surfaceContainerHighest;
    return ListView.builder(
      itemExtent: 88,
      itemCount: 6,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: EmberSpacing.screenGutter,
          vertical: EmberSpacing.xs,
        ),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(EmberRadii.card),
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    // Honest one-liner + one primary next action (10-ux-design.md §7).
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EmberSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.card_giftcard_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: EmberSpacing.md),
            Text(
              'Referrals you submit appear here',
              style: Theme.of(context).textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    // Retryable error: plain language + retry; never raw exception text.
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(EmberSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Couldn't load referrals",
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: EmberSpacing.md),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
