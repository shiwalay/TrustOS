import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Account Standing — the member view of the enforcement system (docs/18 §2).
/// Explanation-first, mirroring the trust-score UX: your standing, the
/// three-strike ladder, what's instant, and that every action is appealable.
/// Demo: good standing; production reads moderation-service.
class StandingScreen extends StatelessWidget {
  const StandingScreen({super.key});

  static const _strikeCount = 0; // demo user is in good standing

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final green = isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final caution = isDark ? EmberColors.cautionDark : EmberColors.cautionLight;
    final critical =
        isDark ? EmberColors.criticalDark : EmberColors.criticalLight;

    return Scaffold(
      appBar: AppBar(title: const Text('Account standing')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Card(
            child: Container(
              padding: const EdgeInsets.all(EmberSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EmberRadii.card),
                border: Border.all(color: green.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified_user_outlined, color: green, size: 34),
                  const SizedBox(height: EmberSpacing.sm),
                  Text('Good standing', style: theme.textTheme.headlineMedium),
                  const SizedBox(height: EmberSpacing.xxs),
                  Text('$_strikeCount of 3 warnings',
                      style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: EmberSpacing.md),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      for (var i = 0; i < 3; i++)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 5),
                          width: 44,
                          height: 8,
                          decoration: BoxDecoration(
                            color: i < _strikeCount
                                ? caution
                                : theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          _label(theme, 'HOW ENFORCEMENT WORKS'),
          const SizedBox(height: EmberSpacing.xs),
          _rule(theme, caution, Icons.warning_amber_outlined,
              'Three upheld warnings',
              'Minor and major violations earn a warning. Three that survive '
              'appeal end in a permanent, identity-bound ban.'),
          _rule(theme, critical, Icons.gpp_bad_outlined,
              'Some things are instant',
              'Fraud, selling invitations, manipulating trust, or illegal '
              'content skip the ladder — immediate permanent ban.'),
          _rule(theme, green, Icons.balance_outlined,
              'Everything is appealable',
              'Every warning and every ban comes with the rule, the evidence, '
              'and a 7-day human-reviewed appeal. A warning only counts once '
              'upheld.'),
          _rule(theme, theme.colorScheme.tertiary, Icons.savings_outlined,
              'Earned money stays yours',
              'A ban never confiscates commissions you already earned — '
              'unless the ban is for fraud on those very earnings.'),
          const SizedBox(height: EmberSpacing.md),
          Text(
            'Vouches mean something here because the rules have teeth. Your '
            'inviter’s trust rides on your conduct, and yours on the people '
            'you invite.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _rule(ThemeData theme, Color color, IconData icon, String title,
          String body) =>
      Card(
        margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
        child: Padding(
          padding: const EdgeInsets.all(EmberSpacing.cardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: EmberSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: theme.textTheme.titleMedium),
                    const SizedBox(height: EmberSpacing.xxs),
                    Text(body,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );

  Widget _label(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
}
