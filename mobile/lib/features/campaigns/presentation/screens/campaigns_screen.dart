import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the campaigns module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class CampaignsScreen extends StatelessWidget {
  const CampaignsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'My Campaigns',
      icon: Icons.campaign_outlined,
      showAppBar: true,
    );
  }
}
