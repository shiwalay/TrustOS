import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the copilot module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class CopilotScreen extends StatelessWidget {
  const CopilotScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Copilot',
      icon: Icons.auto_awesome_outlined,
      showAppBar: true,
    );
  }
}
