import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/components/trust_band_ring.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Step 1 — the promise. One calm screen, one CTA; rotating value points
/// instead of a swipe carousel (no carousel fatigue).
class WelcomeStep extends StatefulWidget {
  const WelcomeStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  State<WelcomeStep> createState() => _WelcomeStepState();
}

class _WelcomeStepState extends State<WelcomeStep> {
  static const _valuePoints = [
    'Turn introductions into income.',
    'A trust score you can actually explain.',
    'Your network, working while you sleep.',
  ];

  int _pointIndex = 0;
  Timer? _rotation;

  @override
  void initState() {
    super.initState();
    _rotation = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() => _pointIndex = (_pointIndex + 1) % _valuePoints.length);
    });
  }

  @override
  void dispose() {
    _rotation?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(EmberSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Spacer(),
          // Trust-band ring motif: the product's core artifact, previewed.
          const Center(
            child: TrustBandRing(
              score: 712,
              size: 148,
              semanticsLabel: 'Example Digital Trust Index',
            ),
          ),
          const SizedBox(height: EmberSpacing.xl),
          Text(
            'Your relationships are\nyour net worth.',
            style: theme.textTheme.displaySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: EmberSpacing.md),
          SizedBox(
            height: 48,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 320),
              child: Text(
                _valuePoints[_pointIndex],
                key: ValueKey(_pointIndex),
                style: theme.textTheme.bodyLarge
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const Spacer(),
          FilledButton(
            onPressed: widget.onNext,
            child: const Text('Get started'),
          ),
          const SizedBox(height: EmberSpacing.md),
        ],
      ),
    );
  }
}
