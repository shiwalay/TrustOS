import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the communities module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class CommunitiesScreen extends StatelessWidget {
  const CommunitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Communities',
      icon: Icons.groups_outlined,
      showAppBar: false,
    );
  }
}
