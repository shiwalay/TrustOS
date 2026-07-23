import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/routes.dart';
import '../../../../core/demo/demo_providers.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/storage/app_database.dart';

/// Network tab — relationships ranked by strength, quiet ties flagged
/// (10-ux-design.md §2.1). Reads the seeded Drift contacts; the production
/// source is relationship-service via the BFF, same shape.
class NetworkScreen extends ConsumerWidget {
  const NetworkScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final contacts = ref.watch(demoContactsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Network')),
      body: contacts.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load network: $e')),
        data: (rows) {
          final businesses = rows.where((c) => c.runsBusiness).length;
          final quiet = rows.where((c) => c.daysSinceInteraction >= 30).length;
          return ListView(
            padding: const EdgeInsets.all(EmberSpacing.screenGutter),
            children: [
              Text(
                '${rows.length} relationships · $businesses run businesses · '
                '$quiet going quiet',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: EmberSpacing.sm),
              Card(
                child: ListTile(
                  leading: Icon(Icons.forum_outlined,
                      color: theme.colorScheme.tertiary),
                  title: const Text('Ask & Offer board'),
                  subtitle: const Text(
                      'Post what you need or can give — the network responds'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.board),
                ),
              ),
              const SizedBox(height: EmberSpacing.xs),
              Card(
                child: ListTile(
                  leading: Icon(Icons.hub_outlined,
                      color: theme.colorScheme.tertiary),
                  title: const Text('Trusted Connectors'),
                  subtitle: const Text(
                      'The person to call for every problem — or become one'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push(Routes.connectors),
                ),
              ),
              const SizedBox(height: EmberSpacing.md),
              for (final c in rows) _RelationshipTile(contact: c),
            ],
          );
        },
      ),
    );
  }
}

class _RelationshipTile extends StatelessWidget {
  const _RelationshipTile({required this.contact});

  final ContactRow contact;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final caution = isDark ? EmberColors.cautionDark : EmberColors.cautionLight;
    final quiet = contact.daysSinceInteraction >= 30;
    final initials = contact.name
        .split(' ')
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0])
        .join();

    return Card(
      margin: const EdgeInsets.only(bottom: EmberSpacing.xs),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: theme.colorScheme.tertiary.withValues(alpha: 0.15),
          foregroundColor: theme.colorScheme.tertiary,
          child: Text(initials),
        ),
        title: Row(
          children: [
            Flexible(
              child: Text(contact.name, overflow: TextOverflow.ellipsis),
            ),
            if (quiet) ...[
              const SizedBox(width: EmberSpacing.xs),
              Icon(Icons.nightlight_outlined, size: 14, color: caution),
              Text(
                ' ${contact.daysSinceInteraction}d quiet',
                style: theme.textTheme.bodySmall?.copyWith(color: caution),
              ),
            ],
          ],
        ),
        subtitle: Text('${contact.company} · ${contact.city}'),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${contact.relationshipStrength}',
              style: theme.textTheme.titleMedium
                  ?.copyWith(color: theme.colorScheme.tertiary),
            ),
            Text('strength', style: theme.textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
