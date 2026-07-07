import 'package:flutter/material.dart';

import '../../../../core/design_system/components/module_placeholder.dart';

/// Placeholder surface for the contacts module (three-layer skeleton;
/// see docs/09-mobile-architecture.md §2 for the target file layout).
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const ModulePlaceholder(
      title: 'Contacts',
      icon: Icons.contacts_outlined,
      showAppBar: true,
    );
  }
}
