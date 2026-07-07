import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../domain/invite_code.dart';

/// Step 2 — the invitation gate. TrustOS is invitation-only: an invite IS a
/// vouch (docs/15). The gate is scarcity with warmth — the copy sells being
/// chosen, and "Request an invitation" keeps the door visibly ajar for
/// uninvited arrivals (waitlist; never a dead end).
class InviteStep extends StatefulWidget {
  const InviteStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  State<InviteStep> createState() => _InviteStepState();
}

class _InviteStepState extends State<InviteStep> {
  final _codeController = TextEditingController();

  String? _error;
  String? _inviterName;

  bool get _accepted => _inviterName != null;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _redeem() {
    final result = InviteCode.validate(_codeController.text);
    setState(() {
      _error = result.error;
      _inviterName = result.inviterName;
    });
  }

  void _joinWaitlist() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Waitlist noted — members near you are sent your request first.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final gold = theme.colorScheme.tertiary;

    return Padding(
      padding: const EdgeInsets.all(EmberSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: EmberSpacing.lg),
          Text('TrustOS is invitation-only',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: EmberSpacing.xs),
          Text(
            'Every member is vouched for by someone already inside. '
            'Your invitation becomes the first thread of your trust graph.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.lg),
          TextField(
            controller: _codeController,
            enabled: !_accepted,
            textCapitalization: TextCapitalization.characters,
            onSubmitted: (_) => _redeem(),
            decoration: InputDecoration(
              labelText: 'Invitation code',
              hintText: 'TRUST-XXXX',
              errorText: _error,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: EmberSpacing.xxs),
          Text(
            'Demo mode — use TRUST-DEMO.',
            style: theme.textTheme.bodySmall?.copyWith(
              color: isDark ? EmberColors.infoDark : EmberColors.infoLight,
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          if (!_accepted)
            FilledButton(
              onPressed: _redeem,
              child: const Text('Redeem invitation'),
            ),
          if (_accepted) ...[
            Container(
              padding: const EdgeInsets.all(EmberSpacing.sm),
              decoration: BoxDecoration(
                color: gold.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(EmberRadii.card),
                border: Border.all(color: gold.withValues(alpha: 0.35)),
              ),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_outlined, color: gold),
                  const SizedBox(width: EmberSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Invited by $_inviterName',
                          style: theme.textTheme.bodyLarge
                              ?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: EmberSpacing.xxs),
                        Text(
                          'They staked a slice of their trust on you.',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.check_circle_outline, color: positive),
                ],
              ),
            ),
          ],
          const Spacer(),
          if (_accepted)
            FilledButton(
              onPressed: widget.onNext,
              child: const Text('Continue'),
            )
          else
            TextButton(
              onPressed: _joinWaitlist,
              child: const Text('No invitation? Request one'),
            ),
          const SizedBox(height: EmberSpacing.md),
        ],
      ),
    );
  }
}
