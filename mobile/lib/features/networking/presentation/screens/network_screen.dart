import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';

/// Network tab root — people: contacts, relationships, matches, intros
/// (10-ux-design.md §2.1). Skeleton: hub tiles into the module stubs.
class NetworkScreen extends StatelessWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.contacts_outlined),
            title: const Text('Contacts'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.contacts),
          ),
          ListTile(
            leading: const Icon(Icons.timeline_outlined),
            title: const Text('Relationships'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go(Routes.relationships),
          ),
          const ListTile(
            leading: Icon(Icons.join_inner_outlined),
            title: Text('Matches'),
            subtitle: Text('Recommendations land in a later milestone'),
            enabled: false,
          ),
          const ListTile(
            leading: Icon(Icons.swap_horiz_outlined),
            title: Text('Intros'),
            subtitle: Text('Double-opt-in intros land in a later milestone'),
            enabled: false,
          ),
        ],
      ),
    );
  }
}
