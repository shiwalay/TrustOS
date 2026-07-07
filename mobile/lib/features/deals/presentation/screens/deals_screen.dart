import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the deals module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class DealsScreen extends StatelessWidget {
  const DealsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'My Deals',
      icon: Icons.handshake_outlined,
      showAppBar: true,
    );
  }
}
