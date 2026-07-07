import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';

/// Invitations — the member's side of the invite-only gate (docs/15).
/// An invite IS a vouch: codes are scarce (5 per member), each redemption
/// creates the invitee's first trust edge and stakes a slice of the
/// inviter's vouch weight. Demo: static code + copy-to-clipboard message;
/// production issues single-use codes via identity-service.
class InvitesScreen extends StatelessWidget {
  const InvitesScreen({super.key});

  static const _personalCode = 'TRUST-RVK7-GOLD';
  static const _remaining = 3;
  static const _total = 5;

  static const _inviteMessage =
      'You are one of the few people I would vouch for, so I am using one of '
      'my five TrustOS invitations on you.\n\n'
      'TrustOS is an invitation-only network where your relationships become '
      'measurable net worth — verified referrals, trusted introductions, '
      'real business.\n\n'
      'My code: $_personalCode\n'
      'Join at trustos.com/join';

  Future<void> _copyInvite(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    await Clipboard.setData(const ClipboardData(text: _inviteMessage));
    messenger.showSnackBar(
      const SnackBar(
        content: Text(
          'Invite message copied — send it to someone you would vouch for.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          // The code card — a brand moment: gold on raised surface.
          Card(
            child: Container(
              padding: const EdgeInsets.all(EmberSpacing.lg),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(EmberRadii.card),
                border: Border.all(color: gold.withValues(alpha: 0.4)),
              ),
              child: Column(
                children: [
                  Text(
                    'YOUR INVITATION CODE',
                    style: EmberTypography.wordmark
                        .copyWith(fontSize: 11, color: gold),
                  ),
                  const SizedBox(height: EmberSpacing.sm),
                  Text(
                    _personalCode,
                    style: theme.textTheme.headlineMedium?.copyWith(
                      letterSpacing: 2,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: EmberSpacing.sm),
                  Text(
                    '$_remaining of $_total invitations left',
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          Text(
            'An invitation is a vouch. Whoever joins with your code starts '
            'their trust graph connected to yours — their conduct reflects '
            'on your vouch weight. Choose people you would put your name on.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Text(
            'YOUR INVITE MESSAGE',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Text(_inviteMessage, style: theme.textTheme.bodyMedium),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          FilledButton.icon(
            onPressed: () => _copyInvite(context),
            icon: const Icon(Icons.copy_all_outlined),
            label: const Text('Copy invite message'),
          ),
          const SizedBox(height: EmberSpacing.sm),
          Text(
            'Paste it into WhatsApp, email, or anywhere else. When they join, '
            'you will see it here — and your vouch becomes their first edge.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
