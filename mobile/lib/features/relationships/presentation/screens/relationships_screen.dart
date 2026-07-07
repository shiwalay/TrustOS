import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the relationships module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class RelationshipsScreen extends StatelessWidget {
  const RelationshipsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Relationships',
      icon: Icons.timeline_outlined,
      showAppBar: true,
    );
  }
}
