import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/ui/demo_feedback.dart';

/// Contacts — import sources and hygiene (contact-service). Demo state:
/// one source connected, dedupe review queue visible.
class ContactsScreen extends StatelessWidget {
  const ContactsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;
    final gold = theme.colorScheme.tertiary;

    return Scaffold(
      appBar: AppBar(title: const Text('Contacts')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          Card(
            child: ListTile(
              leading: Icon(Icons.check_circle_outline, color: positive),
              title: const Text('Phone contacts'),
              subtitle:
                  const Text('Connected · 15 imported · synced 2h ago'),
              trailing: TextButton(
                onPressed: () => showDemoSnack(
                    context, 'Re-syncing your contacts…', icon: Icons.sync),
                child: const Text('Re-sync'),
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: ListTile(
              leading: Icon(Icons.add_circle_outline, color: gold),
              title: const Text('Google contacts'),
              subtitle: const Text('Connect to enrich titles & companies'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDemoSnack(context,
                  'Google Contacts connected — enriching titles & companies…'),
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: ListTile(
              leading: Icon(Icons.upload_file_outlined, color: gold),
              title: const Text('CSV / CRM import'),
              subtitle: const Text('HubSpot, Zoho, or a plain export'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => showDemoSnack(context,
                  'Import a CSV or CRM export to bring your book in.'),
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Text(
            'HYGIENE',
            style: theme.textTheme.bodySmall?.copyWith(
              letterSpacing: 1.4,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: ListTile(
              leading: const Icon(Icons.merge_outlined),
              title: const Text('2 possible duplicates'),
              subtitle: const Text(
                  '"Meera Joshi" ↔ "Meera J (HR)" — review the merge'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () =>
                  showDemoSnack(context, 'Merged — 1 duplicate resolved.'),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          Text(
            'Contacts stay yours. Matching is private; nobody is messaged '
            'without you; people not on TrustOS are never profiled.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}
