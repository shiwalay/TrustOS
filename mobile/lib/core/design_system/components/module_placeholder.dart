import 'package:flutter/material.dart';

import '../tokens/spacing.dart';

/// Shared scaffold for not-yet-built module surfaces, so stub screens are
/// honest ("coming in a later milestone") instead of blank.
class ModulePlaceholder extends StatelessWidget {
  const ModulePlaceholder({
    required this.title,
    required this.icon,
    this.subtitle = 'This module is scaffolded — surfaces land in a later milestone.',
    this.showAppBar = true,
    super.key,
  });

  final String title;
  final IconData icon;
  final String subtitle;
  final bool showAppBar;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: showAppBar ? AppBar(title: Text(title)) : null,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(EmberSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: EmberSpacing.md),
              Text(title, style: theme.textTheme.headlineMedium),
              const SizedBox(height: EmberSpacing.xs),
              Text(
                subtitle,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
