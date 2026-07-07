import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/session/onboarding_state.dart';

/// You tab root — identity, trust profile, rewards, deals, campaigns,
/// leaderboards, settings (10-ux-design.md §2.1: self-inspection in one
/// place builds score literacy). Hosted by the settings feature.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('You')),
      body: ListView(
        children: [
          _tile(context, Icons.workspace_premium_outlined, 'Trust profile',
              Routes.trustProfile),
          _tile(context, Icons.card_membership_outlined, 'Invitations',
              Routes.invites),
          _tile(context, Icons.token_outlined, 'Rewards', Routes.rewards),
          _tile(context, Icons.handshake_outlined, 'My deals', Routes.deals),
          _tile(context, Icons.campaign_outlined, 'My campaigns',
              Routes.campaigns),
          _tile(context, Icons.leaderboard_outlined, 'Leaderboards',
              Routes.leaderboards),
          _tile(context, Icons.verified_user_outlined,
              'Identity & verification', Routes.identity),
          _tile(context, Icons.settings_outlined, 'Settings', Routes.settings),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.replay_outlined),
            title: const Text('Replay onboarding'),
            subtitle: const Text('Demo: walk the first-session flow again'),
            onTap: () => ref.read(onboardedProvider.notifier).replay(),
          ),
        ],
      ),
    );
  }

  Widget _tile(
    BuildContext context,
    IconData icon,
    String title,
    String route,
  ) =>
      ListTile(
        leading: Icon(icon),
        title: Text(title),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.go(route),
      );
}
