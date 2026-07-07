import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';
import '../../domain/entities/referral.dart';
import 'referral_status_chip.dart';

/// Fixed-height tile (used with `itemExtent` — 09 §6 scrolling budget).
class ReferralListTile extends StatelessWidget {
  const ReferralListTile(this.referral, {super.key});

  final Referral referral;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: EmberSpacing.screenGutter,
        vertical: EmberSpacing.xs,
      ),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(EmberSpacing.sm),
          child: Row(
            children: [
              CircleAvatar(
                child: Text(
                  referral.prospectName.isEmpty
                      ? '?'
                      : referral.prospectName[0].toUpperCase(),
                ),
              ),
              const SizedBox(width: EmberSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      referral.prospectName,
                      style: theme.textTheme.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      referral.note,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: EmberSpacing.xs),
              ReferralStatusChip(status: referral.status),
            ],
          ),
        ),
      ),
    );
  }
}
