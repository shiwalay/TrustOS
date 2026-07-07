import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';

/// Invitations — the member's side of the invite-only gate (docs/15 §7.1).
/// An invite IS a vouch: codes are scarce (5 per member), each redemption
/// creates the invitee's first trust edge and stakes a slice of the
/// inviter's vouch weight.
///
/// "Requests near you" is the waitlist loop: uninvited demand from the
/// landing page routes to nearby, industry-matched members as
/// community-invite opportunities — the platform never admits anyone
/// itself; a member always spends the vouch. Demo: in-memory requests;
/// production consumes `identity.waitlist.joined.v1` via networking-service.
class InvitesScreen extends StatefulWidget {
  const InvitesScreen({super.key});

  @override
  State<InvitesScreen> createState() => _InvitesScreenState();
}

class _WaitlistRequest {
  _WaitlistRequest(this.initials, this.who, this.detail, this.fit);
  final String initials;
  final String who;
  final String detail;
  final String fit;
  bool invited = false;
  bool passed = false;
}

class _InvitesScreenState extends State<InvitesScreen> {
  static const _personalCode = 'TRUST-RVK7-GOLD';
  static const _total = 5;
  int _remaining = 3;

  static const _inviteMessage =
      'You are one of the few people I would vouch for, so I am using one of '
      'my five TrustOS invitations on you.\n\n'
      'TrustOS is an invitation-only network where your relationships become '
      'measurable net worth — verified referrals, trusted introductions, '
      'real business.\n\n'
      'My code: $_personalCode\n'
      'Join at trustos.com/join';

  final List<_WaitlistRequest> _requests = [
    _WaitlistRequest(
      'SG',
      'Sanjay Gupta · Packaging manufacturer',
      'Andheri, Mumbai · requested 2 days ago',
      'Fits your manufacturing circle · 2 mutual industries',
    ),
    _WaitlistRequest(
      'NT',
      'Neha Trivedi · Brand consultant',
      'Bandra, Mumbai · requested 5 days ago',
      'Matches your D2C referral track record',
    ),
  ];

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

  void _invite(_WaitlistRequest r) {
    if (_remaining == 0) return;
    setState(() {
      r.invited = true;
      _remaining -= 1;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Invitation sent to ${r.who.split(' ·').first} — your vouch is '
          'now their first trust edge.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final visible = _requests.where((r) => !r.passed).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Invitations')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
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
          if (visible.isNotEmpty) ...[
            const SizedBox(height: EmberSpacing.lg),
            _label(theme, 'REQUESTS NEAR YOU'),
            const SizedBox(height: EmberSpacing.xxs),
            Text(
              'People without an invitation joined the waitlist. Matched to '
              'you by city and industry — inviting one spends a vouch.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: EmberSpacing.xs),
            for (final r in visible)
              Card(
                margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
                child: Padding(
                  padding: const EdgeInsets.all(EmberSpacing.sm),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor:
                                gold.withValues(alpha: 0.15),
                            foregroundColor: gold,
                            child: Text(r.initials),
                          ),
                          const SizedBox(width: EmberSpacing.sm),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(r.who,
                                    style: theme.textTheme.bodyLarge
                                        ?.copyWith(
                                            fontWeight: FontWeight.w600)),
                                Text(r.detail,
                                    style: theme.textTheme.bodySmall),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: EmberSpacing.xs),
                      Text(
                        r.fit,
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: gold),
                      ),
                      const SizedBox(height: EmberSpacing.sm),
                      if (r.invited)
                        Row(
                          children: [
                            Icon(Icons.check_circle_outline,
                                size: 18, color: positive),
                            const SizedBox(width: EmberSpacing.xs),
                            Text(
                              'Invited — they join with your vouch',
                              style: theme.textTheme.bodySmall
                                  ?.copyWith(color: positive),
                            ),
                          ],
                        )
                      else
                        Row(
                          children: [
                            Expanded(
                              child: FilledButton(
                                onPressed: _remaining > 0
                                    ? () => _invite(r)
                                    : null,
                                style: FilledButton.styleFrom(
                                  minimumSize: const Size(0, 40),
                                ),
                                child: const Text('Invite — spend a vouch'),
                              ),
                            ),
                            const SizedBox(width: EmberSpacing.xs),
                            TextButton(
                              onPressed: () =>
                                  setState(() => r.passed = true),
                              child: const Text('Pass'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
          ],
          const SizedBox(height: EmberSpacing.lg),
          _label(theme, 'YOUR INVITE MESSAGE'),
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

  Widget _label(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
}
