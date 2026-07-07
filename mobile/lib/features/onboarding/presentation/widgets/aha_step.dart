import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_providers.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/session/onboarding_state.dart';

/// Step 4 — THE REVEAL (docs/10-ux-design.md §5.1): three insights about
/// the user's own network, staggered in like a gift. Completing here flips
/// the onboarded flag; the router redirect lands on Home.
class AhaStep extends ConsumerWidget {
  const AhaStep({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final insights = ref.watch(ahaInsightsProvider);

    return Padding(
      padding: const EdgeInsets.all(EmberSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: EmberSpacing.lg),
          Text("Here's what we found",
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: EmberSpacing.xs),
          Text(
            'Three things already true about your network.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Expanded(
            child: insights.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (_, __) => const SizedBox.shrink(),
              data: (cards) => ListView.separated(
                itemCount: cards.length,
                separatorBuilder: (_, __) =>
                    const SizedBox(height: EmberSpacing.sm),
                itemBuilder: (context, i) => _InsightCard(
                  insight: cards[i],
                  delay: Duration(milliseconds: 200 * i),
                ),
              ),
            ),
          ),
          FilledButton(
            onPressed: () =>
                ref.read(onboardedProvider.notifier).complete(),
            child: const Text('Enter TrustOS'),
          ),
          const SizedBox(height: EmberSpacing.md),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  const _InsightCard({required this.insight, required this.delay});

  final AhaInsight insight;
  final Duration delay;

  IconData get _icon => switch (insight.kind) {
        InsightKind.network => Icons.hub_outlined,
        InsightKind.reconnect => Icons.favorite_outline,
        InsightKind.earn => Icons.card_giftcard_outlined,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Staggered entrance: each card fades/slides in slightly after the last.
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 400 + delay.inMilliseconds),
      curve: Curves.easeOutCubic,
      builder: (context, t, child) => Opacity(
        opacity: t.clamp(0, 1),
        child: Transform.translate(
          offset: Offset(0, 16 * (1 - t)),
          child: child,
        ),
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(EmberSpacing.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor:
                    theme.colorScheme.primary.withValues(alpha: 0.12),
                child: Icon(_icon, size: 20, color: theme.colorScheme.primary),
              ),
              const SizedBox(width: EmberSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: EmberSpacing.xxs),
                    Text(
                      insight.body,
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
