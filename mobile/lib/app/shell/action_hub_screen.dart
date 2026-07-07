import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/design_system/tokens/spacing.dart';
import '../router/routes.dart';

/// ➕ Act — center tab (10-ux-design.md §2.1): the write verbs under the
/// thumb. Lives in app/shell because it is pure navigation chrome fanning
/// out into feature flows; only "Submit referral" is live in the skeleton.
class ActionHubScreen extends StatelessWidget {
  const ActionHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Act')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          _verb(
            context,
            icon: Icons.card_giftcard_outlined,
            title: 'Submit referral',
            subtitle: 'Offline-safe — queued and confirmed',
            onTap: () =>
                context.push(Routes.campaignReferrals(Routes.demoCampaignId)),
          ),
          _verb(context,
              icon: Icons.swap_horiz_outlined, title: 'Request intro'),
          _verb(context,
              icon: Icons.campaign_outlined, title: 'Compose campaign'),
          _verb(context, icon: Icons.handshake_outlined, title: 'Log deal'),
          _verb(context,
              icon: Icons.person_add_alt_outlined, title: 'Add contact'),
          _verb(
            context,
            icon: Icons.auto_awesome_outlined,
            title: 'Ask copilot',
            onTap: () => context.push(Routes.copilot),
          ),
        ],
      ),
    );
  }

  Widget _verb(
    BuildContext context, {
    required IconData icon,
    required String title,
    String? subtitle,
    VoidCallback? onTap,
  }) =>
      Card(
        margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
        child: ListTile(
          leading: Icon(icon),
          title: Text(title),
          subtitle: Text(subtitle ?? 'Lands in a later milestone'),
          trailing: const Icon(Icons.chevron_right),
          enabled: onTap != null,
          onTap: onTap,
        ),
      );
}
