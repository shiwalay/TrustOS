import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the settings module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Settings',
      icon: Icons.settings_outlined,
      showAppBar: true,
    );
  }
}
