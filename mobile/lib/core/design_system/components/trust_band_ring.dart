import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/trust_band_colors.dart';

/// TrustBandRing — stub of the Ember "TrustRing" (10-ux-design.md W5 ①).
///
/// 0–1000 arc with the band label INSIDE the ring: band is encoded by
/// color + label + segment count, never color alone (§4.2). Semantics per
/// 09-mobile-architecture.md §7 — informational, not adjustable.
class TrustBandRing extends StatelessWidget {
  const TrustBandRing({
    required this.score,
    this.size = 120,
    this.semanticsLabel = 'Digital Trust Index',
    super.key,
  });

  /// DTI in [0, 1000] (_shared-context.md §4).
  final int score;
  final double size;
  final String semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final band = TrustBand.fromScore(score);
    final bandColors = Theme.of(context).extension<TrustBandColors>()!;
    final color = bandColors.of(band);

    // RepaintBoundary: rings sit inside scrolling tiles (09 §6 scroll budget).
    return Semantics(
      label: semanticsLabel,
      value: '$score out of 1000, ${band.label} band',
      hint: 'Double tap to see what makes up your score',
      child: ExcludeSemantics(
        child: RepaintBoundary(
          child: SizedBox.square(
            dimension: size,
            child: CustomPaint(
              painter: _TrustRingPainter(
                progress: score.clamp(0, 1000) / 1000,
                segments: band.ringSegments,
                color: color,
                trackColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$score',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    Text(
                      band.label.toUpperCase(),
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: color, letterSpacing: 1.2),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TrustRingPainter extends CustomPainter {
  const _TrustRingPainter({
    required this.progress,
    required this.segments,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final int segments;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    const strokeWidth = 10.0;
    final arcRect = rect.deflate(strokeWidth / 2);
    const start = -math.pi / 2;

    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..color = trackColor;
    canvas.drawArc(arcRect, 0, math.pi * 2, false, track);

    final arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(arcRect, start, math.pi * 2 * progress, false, arc);

    // Band segment ticks (1..5): the redundant, non-color band encoding.
    final tick = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth / 2
      ..strokeCap = StrokeCap.round
      ..color = color;
    for (var i = 0; i < segments; i++) {
      final angle = start + (math.pi * 2 / 5) * i;
      canvas.drawArc(arcRect.deflate(strokeWidth), angle, 0.12, false, tick);
    }
  }

  @override
  bool shouldRepaint(_TrustRingPainter old) =>
      old.progress != progress ||
      old.segments != segments ||
      old.color != color ||
      old.trackColor != trackColor;
}
