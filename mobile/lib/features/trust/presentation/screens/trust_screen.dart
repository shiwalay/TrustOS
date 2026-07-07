import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the trust module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class TrustProfileScreen extends StatelessWidget {
  const TrustProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Your Trust',
      icon: Icons.workspace_premium_outlined,
      showAppBar: true,
    );
  }
}
