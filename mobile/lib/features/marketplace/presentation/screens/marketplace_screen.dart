import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the marketplace module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class MarketplaceScreen extends StatelessWidget {
  const MarketplaceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Marketplace',
      icon: Icons.storefront_outlined,
      showAppBar: true,
    );
  }
}
