import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the onboarding module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Onboarding',
      icon: Icons.waving_hand_outlined,
      showAppBar: false,
    );
  }
}
