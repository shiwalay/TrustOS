import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the rewards module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class RewardsScreen extends StatelessWidget {
  const RewardsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Rewards',
      icon: Icons.token_outlined,
      showAppBar: true,
    );
  }
}
