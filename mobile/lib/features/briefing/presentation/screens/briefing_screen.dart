import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';

/// Daily Briefing — the member view of a community's 15-minute daily call
/// (docs/18 §1). The AI assembles a timeboxed agenda from the last 24h;
/// members join, run it, and pass referrals live. This demo renders the
/// agenda and the weekly-winner moment (docs/18 §3) without the live-video
/// layer; production joins a LiveKit room via live-service.
class BriefingScreen extends StatelessWidget {
  const BriefingScreen({super.key});

  static const _agenda = [
    ('0:00', '3 min', 'AI briefing', Icons.auto_awesome_outlined,
        'Yesterday: ₹1,500 settled across 3 referrals · 2 new members · '
        'top ask — a CFO intro for Priya. One nudge: Rohan has gone quiet.'),
    ('3:00', '2 min', 'Wins', Icons.emoji_events_outlined,
        'Ledger-verified only. Dr. Arvind Shetty referral settled (₹500).'),
    ('5:00', '5 min', 'Asks & offers', Icons.swap_horiz_outlined,
        'Pre-collected overnight, ordered by match strength. 4 asks, '
        '6 offers ready.'),
    ('10:00', '4 min', 'Live referral exchange', Icons.card_giftcard_outlined,
        'Pass a referral on the spot — captured to the ledger in real time.'),
    ('14:00', '1 min', 'Close', Icons.check_circle_outline,
        'Commitments recap. The AI turns them into follow-ups automatically.'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;
    final isDark = theme.brightness == Brightness.dark;
    final green = isDark ? EmberColors.positiveDark : EmberColors.positiveLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Daily Briefing')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          // Live header
          Card(
            child: Container(
              padding: const EdgeInsets.all(EmberSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EmberRadii.card),
                border: Border.all(color: gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration:
                            BoxDecoration(color: green, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: EmberSpacing.xs),
                      Text('STARTS 9:00 AM · 15 MIN',
                          style: EmberTypography.wordmark
                              .copyWith(fontSize: 11, color: green)),
                    ],
                  ),
                  const SizedBox(height: EmberSpacing.sm),
                  Text('Mumbai Founders Circle',
                      style: theme.textTheme.headlineMedium),
                  const SizedBox(height: EmberSpacing.xxs),
                  Text('Your daily briefing — 12 members usually join',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: EmberSpacing.md),
                  FilledButton.icon(
                    onPressed: () => showModalBottomSheet<void>(
                      context: context,
                      builder: (_) => const _JoinSheet(),
                    ),
                    icon: const Icon(Icons.videocam_outlined),
                    label: const Text('Join the call'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),

          // This week's winner (feature 3)
          _WinnerCard(gold: gold),
          const SizedBox(height: EmberSpacing.lg),

          Text("TODAY'S AGENDA",
              style: theme.textTheme.bodySmall?.copyWith(
                  letterSpacing: 1.4,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: EmberSpacing.xs),
          for (final (at, dur, title, icon, body) in _agenda)
            Card(
              margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
              child: Padding(
                padding: const EdgeInsets.all(EmberSpacing.cardPadding),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Icon(icon, color: gold, size: 22),
                        const SizedBox(height: 4),
                        Text(at,
                            style: theme.textTheme.bodySmall?.copyWith(
                                fontFeatures: const [
                                  FontFeature.tabularFigures()
                                ],
                                color: theme.colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(width: EmberSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                  child: Text(title,
                                      style: theme.textTheme.titleMedium)),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: EmberSpacing.xs, vertical: 2),
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest,
                                  borderRadius:
                                      BorderRadius.circular(EmberRadii.chip),
                                ),
                                child: Text(dur,
                                    style: theme.textTheme.bodySmall),
                              ),
                            ],
                          ),
                          const SizedBox(height: EmberSpacing.xxs),
                          Text(body,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                  color:
                                      theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            'Attendance is optional and never scored. What counts is what you '
            'bring — a referral passed here settles through the ledger like '
            'any other.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _WinnerCard extends StatelessWidget {
  const _WinnerCard({required this.gold});
  final Color gold;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(EmberSpacing.cardPadding),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: gold.withValues(alpha: 0.15),
                border: Border.all(color: gold.withValues(alpha: 0.5)),
              ),
              child: Icon(Icons.emoji_events_outlined, color: gold),
            ),
            const SizedBox(width: EmberSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('THIS WEEK’S WINNER · TOP REFERRER',
                      style: EmberTypography.wordmark
                          .copyWith(fontSize: 10, color: gold)),
                  const SizedBox(height: 3),
                  Text('Priya Sharma', style: theme.textTheme.titleMedium),
                  Text('₹4.2L verified business · 8 settled conversions',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _JoinSheet extends StatelessWidget {
  const _JoinSheet();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EmberSpacing.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.videocam_outlined,
              size: 40, color: theme.colorScheme.tertiary),
          const SizedBox(height: EmberSpacing.sm),
          Text('Connecting you to the room…',
              style: theme.textTheme.titleMedium),
          const SizedBox(height: EmberSpacing.xs),
          Text(
            'In the live app this joins a LiveKit room (audio-first, '
            'in-region). This is the demo build — the agenda above is what '
            'you would run together.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.md),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
