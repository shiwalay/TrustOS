import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the identity module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class IdentityScreen extends StatelessWidget {
  const IdentityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Identity & verification',
      icon: Icons.verified_user_outlined,
      showAppBar: true,
    );
  }
}
