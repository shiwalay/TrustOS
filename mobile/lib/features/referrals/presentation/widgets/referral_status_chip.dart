import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../domain/entities/referral.dart';

/// Status chip incl. the "Pending sync" state (offline UX contract,
/// 10-ux-design.md §7 row-level truth). Trust-calm styling: pending uses
/// `caution` amber — never red; red is reserved for errors, and even
/// `rejected` reads as informational, not alarming.
class ReferralStatusChip extends StatelessWidget {
  const ReferralStatusChip({required this.status, super.key});

  final ReferralStatus status;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final (label, color) = switch (status) {
      ReferralStatus.pendingSync => (
          'Pending sync',
          isDark ? EmberColors.cautionDark : EmberColors.cautionLight,
        ),
      ReferralStatus.submitted => (
          'Submitted',
          isDark ? EmberColors.infoDark : EmberColors.infoLight,
        ),
      ReferralStatus.qualified => (
          'Qualified',
          isDark ? EmberColors.infoDark : EmberColors.infoLight,
        ),
      ReferralStatus.converted => (
          'Converted',
          isDark ? EmberColors.positiveDark : EmberColors.positiveLight,
        ),
      ReferralStatus.settled => (
          'Settled',
          isDark ? EmberColors.positiveDark : EmberColors.positiveLight,
        ),
      ReferralStatus.rejected => (
          'Not accepted',
          isDark ? EmberColors.textSecondaryDark : EmberColors.textSecondaryLight,
        ),
      ReferralStatus.expired => (
          'Expired',
          isDark ? EmberColors.textSecondaryDark : EmberColors.textSecondaryLight,
        ),
    };

    return Semantics(
      label: 'Referral status: $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: EmberSpacing.xs,
          vertical: EmberSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(EmberRadii.chip),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (status == ReferralStatus.pendingSync) ...[
              Icon(Icons.hourglass_top_rounded, size: 12, color: color),
              const SizedBox(width: EmberSpacing.xxs),
            ],
            Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}
