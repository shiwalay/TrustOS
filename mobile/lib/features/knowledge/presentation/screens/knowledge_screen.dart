import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the knowledge module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class KnowledgeScreen extends StatelessWidget {
  const KnowledgeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Knowledge',
      icon: Icons.menu_book_outlined,
      showAppBar: true,
    );
  }
}
