import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design_system/components/trust_band_ring.dart';
import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';
import '../../../../core/design_system/tokens/typography.dart';

/// The "How TrustOS works" explainer — an AI-scripted, natively-rendered
/// motion video (five scenes, ~30 s) shown on the contact-import step,
/// where onboarding hesitation peaks.
///
/// Rendered as Flutter animation rather than a bundled MP4: kilobytes not
/// megabytes, theme- and locale-aware, and 60 fps on any device. The
/// production pipeline can swap in an ai-gateway-generated avatar video
/// behind this same player chrome (07-ai-architecture.md §2).

class ExplainerVideoCard extends StatelessWidget {
  const ExplainerVideoCard({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final gold = theme.colorScheme.tertiary;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(EmberRadii.card),
        onTap: () => Navigator.of(context, rootNavigator: true).push(
          PageRouteBuilder<void>(
            opaque: false,
            barrierColor: Colors.black87,
            pageBuilder: (_, __, ___) => const _ExplainerPlayer(),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(EmberSpacing.sm),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: gold.withValues(alpha: 0.15),
                  border: Border.all(color: gold.withValues(alpha: 0.5)),
                ),
                child: Icon(Icons.play_arrow_rounded, color: gold, size: 32),
              ),
              const SizedBox(width: EmberSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Watch: how TrustOS works',
                        style: theme.textTheme.bodyLarge
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '30 seconds — what happens to your contacts, and why',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Player ──────────────────────────────────────────────────────────────

class _Scene {
  const _Scene(this.seconds, this.caption, this.builder);
  final double seconds;
  final String caption;
  final Widget Function(BuildContext, double t) builder;
}

class _ExplainerPlayer extends StatefulWidget {
  const _ExplainerPlayer();

  @override
  State<_ExplainerPlayer> createState() => _ExplainerPlayerState();
}

class _ExplainerPlayerState extends State<_ExplainerPlayer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;

  static final List<_Scene> _scenes = [
    _Scene(5, 'This is TrustOS. Your network is your net worth — '
        'we make it measurable.', (c, t) => _SceneBrand(t: t)),
    _Scene(7, 'Import your contacts and we map who you know — privately. '
        'Nobody is messaged, nobody is profiled.',
        (c, t) => _SceneGraph(t: t)),
    _Scene(6, 'Verified outcomes — referrals, deals, kept promises — '
        'build your Trust Index. It cannot be bought.',
        (c, t) => _SceneTrust(t: t)),
    _Scene(7, 'Then AI finds the opportunities hiding in your network: '
        'referrals, intros, partnerships — and the money settles '
        'through a verified ledger.', (c, t) => _SceneOpportunity(t: t)),
    _Scene(5, 'Contacts stay yours. Nothing sends without you. '
        'Ready to see your network?', (c, t) => _ScenePrivacy(t: t)),
  ];

  static final double _total =
      _scenes.fold(0.0, (sum, s) => sum + s.seconds);

  @override
  void initState() {
    super.initState();
    _timeline = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: (_total * 1000).round()),
    )..forward();
  }

  @override
  void dispose() {
    _timeline.dispose();
    super.dispose();
  }

  (_Scene, double) _current(double v) {
    var elapsed = v * _total;
    for (final s in _scenes) {
      if (elapsed <= s.seconds) {
        return (s, (elapsed / s.seconds).clamp(0.0, 1.0));
      }
      elapsed -= s.seconds;
    }
    return (_scenes.last, 1);
  }

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;

    return Scaffold(
      backgroundColor: EmberColors.surfaceBaseDark,
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _timeline,
          builder: (context, _) {
            final (scene, t) = _current(_timeline.value);
            final done = _timeline.value >= 1;
            return Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(done ? 'Close' : 'Skip',
                        style: const TextStyle(
                            color: EmberColors.textSecondaryDark)),
                  ),
                ),
                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: KeyedSubtree(
                      key: ValueKey(scene.caption),
                      child: scene.builder(context, t),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: EmberSpacing.lg),
                  child: Text(
                    scene.caption,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: EmberColors.textPrimaryDark,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: EmberSpacing.md),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: EmberSpacing.lg),
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () {
                          if (done) {
                            _timeline
                              ..reset()
                              ..forward();
                          } else if (_timeline.isAnimating) {
                            _timeline.stop();
                            setState(() {});
                          } else {
                            _timeline.forward();
                          }
                        },
                        icon: Icon(
                          done
                              ? Icons.replay_rounded
                              : _timeline.isAnimating
                                  ? Icons.pause_rounded
                                  : Icons.play_arrow_rounded,
                          color: gold,
                        ),
                      ),
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(2),
                          child: LinearProgressIndicator(
                            value: _timeline.value,
                            minHeight: 3,
                            backgroundColor: EmberColors.surfaceRaisedDark,
                            color: gold,
                          ),
                        ),
                      ),
                      const SizedBox(width: EmberSpacing.sm),
                      Text(
                        '0:${(_timeline.value * _total).round().toString().padLeft(2, '0')} / 0:${_total.round()}',
                        style: const TextStyle(
                            color: EmberColors.textSecondaryDark,
                            fontSize: 12),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: EmberSpacing.sm),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ── Scenes ──────────────────────────────────────────────────────────────

double _ease(double t, double start, double end) =>
    Curves.easeOutCubic.transform(
        ((t - start) / (end - start)).clamp(0.0, 1.0));

class _SceneBrand extends StatelessWidget {
  const _SceneBrand({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Opacity(
            opacity: _ease(t, 0, .3),
            child: Text('T R U S T O S',
                style: EmberTypography.wordmark.copyWith(color: gold)),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Transform.scale(
            scale: 0.6 + 0.4 * _ease(t, .1, .5),
            child: Opacity(
              opacity: _ease(t, .1, .4),
              child: const TrustBandRing(score: 712, size: 140),
            ),
          ),
          const SizedBox(height: EmberSpacing.lg),
          Opacity(
            opacity: _ease(t, .5, .8),
            child: Text(
              'Your network is\nyour net worth.',
              textAlign: TextAlign.center,
              style: EmberTypography.brandDisplay
                  .copyWith(color: EmberColors.textPrimaryDark, fontSize: 26),
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneGraph extends StatelessWidget {
  const _SceneGraph({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: CustomPaint(
        size: const Size(280, 280),
        painter: _GraphPainter(
          t: t,
          gold: Theme.of(context).colorScheme.tertiary,
        ),
      ),
    );
  }
}

class _GraphPainter extends CustomPainter {
  _GraphPainter({required this.t, required this.gold});
  final double t;
  final Color gold;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    const n = 7;
    final radius = size.width * 0.38;

    final edge = Paint()
      ..color = gold.withValues(alpha: 0.45)
      ..strokeWidth = 1.4;
    final nodeFill = Paint()..color = gold;
    final youFill = Paint()..color = gold.withValues(alpha: 0.9);

    for (var i = 0; i < n; i++) {
      final start = 0.12 + i * 0.09;
      final k = _ease(t, start, start + 0.25);
      if (k <= 0) continue;
      final angle = -math.pi / 2 + i * 2 * math.pi / n;
      final target = center + Offset(math.cos(angle), math.sin(angle)) * radius;
      final tip = Offset.lerp(center, target, k)!;
      canvas.drawLine(center, tip, edge);
      if (k >= 1) {
        canvas.drawCircle(target, 7, nodeFill);
        // second-degree hint: a faint further node
        final far = center +
            Offset(math.cos(angle + .35), math.sin(angle + .35)) *
                (radius * 1.45);
        final k2 = _ease(t, .75, 1);
        if (k2 > 0) {
          canvas.drawLine(target,
              Offset.lerp(target, far, k2)!, edge..strokeWidth = 0.8);
          canvas.drawCircle(
              far,
              4,
              Paint()..color = gold.withValues(alpha: 0.5 * k2));
        }
      }
    }
    canvas.drawCircle(center, 13, youFill);
    final tp = TextPainter(
      text: const TextSpan(
        text: 'You',
        style: TextStyle(
            color: EmberColors.surfaceBaseDark,
            fontSize: 9,
            fontWeight: FontWeight.w700),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, center - Offset(tp.width / 2, tp.height / 2));
  }

  @override
  bool shouldRepaint(_GraphPainter old) => old.t != t;
}

class _SceneTrust extends StatelessWidget {
  const _SceneTrust({required this.t});
  final double t;

  static const _bars = [
    ('Referrals settled', .76),
    ('Identity verified', .79),
    ('Kept meetings', .78),
    ('Community help', .64),
  ];

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;
    final score = (712 * _ease(t, 0, .5)).round();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: EmberSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('$score',
                style: EmberTypography.scoreXL
                    .copyWith(color: gold, fontSize: 56)),
            Text('DIGITAL TRUST INDEX',
                style: EmberTypography.wordmark
                    .copyWith(color: EmberColors.textSecondaryDark,
                        fontSize: 10)),
            const SizedBox(height: EmberSpacing.lg),
            for (var i = 0; i < _bars.length; i++) ...[
              Row(
                children: [
                  SizedBox(
                    width: 130,
                    child: Text(_bars[i].$1,
                        style: const TextStyle(
                            color: EmberColors.textSecondaryDark,
                            fontSize: 12)),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: LinearProgressIndicator(
                        value: _bars[i].$2 *
                            _ease(t, .3 + i * .12, .6 + i * .12),
                        minHeight: 6,
                        backgroundColor: EmberColors.surfaceRaisedDark,
                        color: gold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: EmberSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _SceneOpportunity extends StatelessWidget {
  const _SceneOpportunity({required this.t});
  final double t;

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;
    final positive = EmberColors.positiveDark;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatar('PS', gold, _ease(t, 0, .25)),
              SizedBox(
                width: 90,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: _ease(t, .2, .5),
                    minHeight: 2.4,
                    backgroundColor: EmberColors.surfaceRaisedDark,
                    color: gold,
                  ),
                ),
              ),
              _avatar('DR', gold, _ease(t, .4, .6)),
            ],
          ),
          const SizedBox(height: EmberSpacing.md),
          Opacity(
            opacity: _ease(t, .45, .65),
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: EmberSpacing.sm, vertical: EmberSpacing.xxs),
              decoration: BoxDecoration(
                border: Border.all(color: gold.withValues(alpha: .5)),
                borderRadius: BorderRadius.circular(EmberRadii.chip),
              ),
              child: Text('Warm intro suggested — both sides benefit',
                  style: TextStyle(color: gold, fontSize: 12)),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          Opacity(
            opacity: _ease(t, .7, .9),
            child: Column(
              children: [
                Icon(Icons.verified_outlined, color: positive, size: 28),
                const SizedBox(height: EmberSpacing.xxs),
                Text('₹500 commission settled',
                    style: TextStyle(
                        color: positive,
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
                const Text('verified in the ledger — trust +6',
                    style: TextStyle(
                        color: EmberColors.textSecondaryDark, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _avatar(String initials, Color gold, double k) => Opacity(
        opacity: k,
        child: Transform.scale(
          scale: .7 + .3 * k,
          child: CircleAvatar(
            radius: 24,
            backgroundColor: gold.withValues(alpha: .15),
            foregroundColor: gold,
            child: Text(initials),
          ),
        ),
      );
}

class _ScenePrivacy extends StatelessWidget {
  const _ScenePrivacy({required this.t});
  final double t;

  static const _promises = [
    'Contacts stay on your side of the wall',
    'Nobody is messaged without you',
    'Non-members are never profiled',
  ];

  @override
  Widget build(BuildContext context) {
    final gold = Theme.of(context).colorScheme.tertiary;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Transform.scale(
            scale: .7 + .3 * _ease(t, 0, .3),
            child: Icon(Icons.lock_outline, color: gold, size: 56),
          ),
          const SizedBox(height: EmberSpacing.lg),
          for (var i = 0; i < _promises.length; i++)
            Opacity(
              opacity: _ease(t, .25 + i * .15, .45 + i * .15),
              child: Padding(
                padding: const EdgeInsets.only(bottom: EmberSpacing.xs),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.check, size: 16,
                        color: EmberColors.positiveDark),
                    const SizedBox(width: EmberSpacing.xs),
                    Text(_promises[i],
                        style: const TextStyle(
                            color: EmberColors.textPrimaryDark,
                            fontSize: 14)),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
