import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the leaderboards module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class LeaderboardsScreen extends StatelessWidget {
  const LeaderboardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Business League',
      icon: Icons.leaderboard_outlined,
      showAppBar: true,
    );
  }
}
