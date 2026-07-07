import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/demo/demo_providers.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Step 3 — consent-first contact import (docs/10-ux-design.md W3): the
/// privacy promise comes BEFORE anything happens, and skipping is honest
/// and always available — never dark-patterned.
class ImportStep extends ConsumerStatefulWidget {
  const ImportStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  ConsumerState<ImportStep> createState() => _ImportStepState();
}

class _ImportStepState extends ConsumerState<ImportStep>
    with SingleTickerProviderStateMixin {
  late final AnimationController _progress = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1800),
  )..addStatusListener((status) {
      if (status == AnimationStatus.completed) widget.onNext();
    });

  bool _importing = false;

  @override
  void dispose() {
    _progress.dispose();
    super.dispose();
  }

  void _import() {
    setState(() => _importing = true);
    _progress.forward();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final contactCount = ref.watch(demoContactCountProvider).valueOrNull ?? 0;
    final total = contactCount == 0 ? 15 : contactCount;

    return Padding(
      padding: const EdgeInsets.all(EmberSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: EmberSpacing.lg),
          Text('Bring your network with you',
              style: theme.textTheme.headlineMedium),
          const SizedBox(height: EmberSpacing.md),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(EmberSpacing.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.lock_outline,
                          size: 20, color: theme.colorScheme.primary),
                      const SizedBox(width: EmberSpacing.xs),
                      Text('Contacts stay yours.',
                          style: theme.textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: EmberSpacing.xs),
                  Text(
                    'We match privately, never message anyone without you, '
                    'never show your contacts to other members, and never '
                    'build profiles of people who are not on TrustOS.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          Text(
            'TrustOS reads contacts to map YOUR relationships — who runs '
            'businesses, who is going quiet, who can introduce you.',
            style: theme.textTheme.bodyMedium,
          ),
          const Spacer(),
          if (_importing)
            AnimatedBuilder(
              animation: _progress,
              builder: (context, _) {
                final matched = (_progress.value * total).round();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    LinearProgressIndicator(value: _progress.value),
                    const SizedBox(height: EmberSpacing.xs),
                    Text(
                      'Matching privately… $matched/$total',
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                );
              },
            )
          else ...[
            FilledButton(
              onPressed: _import,
              child: const Text('Import contacts'),
            ),
            const SizedBox(height: EmberSpacing.xs),
            TextButton(
              onPressed: widget.onNext,
              child: const Text('Skip for now'),
            ),
          ],
          const SizedBox(height: EmberSpacing.md),
        ],
      ),
    );
  }
}
