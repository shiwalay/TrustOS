import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/ui/demo_feedback.dart';

/// Settings — privacy first (10-ux-design.md §6: privacy controls are a
/// primary surface, not a buried legal page). Demo state.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _showTrustBand = true;
  bool _discoverable = false;
  bool _dailyDigest = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(EmberSpacing.screenGutter),
        children: [
          _label(theme, 'PRIVACY'),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  value: _showTrustBand,
                  onChanged: (v) => setState(() => _showTrustBand = v),
                  title: const Text('Show my trust band publicly'),
                  subtitle: const Text(
                      'Band only — your number is never shown to others'),
                ),
                SwitchListTile(
                  value: _discoverable,
                  onChanged: (v) => setState(() => _discoverable = v),
                  title: const Text('Discoverable outside my communities'),
                  subtitle:
                      const Text('Off: only members you share a room with'),
                ),
                ListTile(
                  title: const Text('Who can see my relationships'),
                  subtitle: const Text('Nobody — timelines are yours alone'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDemoSnack(
                      context, 'Only you can see your relationships.'),
                ),
              ],
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          _label(theme, 'NOTIFICATIONS'),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Quiet hours'),
                  subtitle: const Text('9:30 pm – 8:00 am IST'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDemoSnack(context, 'Quiet hours updated.'),
                ),
                SwitchListTile(
                  value: _dailyDigest,
                  onChanged: (v) => setState(() => _dailyDigest = v),
                  title: const Text('Daily digest only'),
                  subtitle: const Text(
                      'One morning summary instead of individual pings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          _label(theme, 'DATA'),
          const SizedBox(height: EmberSpacing.xs),
          Card(
            child: Column(
              children: [
                ListTile(
                  title: const Text('Export my data'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDemoSnack(context,
                      'Export requested — we’ll email a download link.'),
                ),
                ListTile(
                  title: const Text('Delete my account'),
                  subtitle: const Text(
                      'Erasure within 30 days — crypto-shredded, for real'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => showDemoSnack(
                    context,
                    'Account deletion needs email confirmation — check your inbox.',
                    icon: Icons.warning_amber_outlined,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Center(
            child: Text(
              'TrustOS 0.1.0 (demo) · ap-south-1',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(ThemeData theme, String text) => Text(
        text,
        style: theme.textTheme.bodySmall?.copyWith(
          letterSpacing: 1.4,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      );
}
