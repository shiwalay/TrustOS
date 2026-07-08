import 'dart:async';

import 'package:flutter/material.dart';

import '../neo_tokens.dart';

/// Neo-Minimal Intelligence — the flagship dashboard, applied to TrustOS.
/// "Less interface. More intelligence." Scannable in five seconds: welcome,
/// the one KPI that matters, the recommended next action, quick actions,
/// recent activity, and an AI recommendation. Demonstrates the skeleton
/// loading state → content. A committed light, single-theme world.
class NeoDashboardScreen extends StatefulWidget {
  const NeoDashboardScreen({super.key});

  @override
  State<NeoDashboardScreen> createState() => _NeoDashboardScreenState();
}

class _NeoDashboardScreenState extends State<NeoDashboardScreen> {
  bool _loading = true;
  Timer? _t;

  @override
  void initState() {
    super.initState();
    // Progressive loading — skeletons first, then content (demo).
    _t = Timer(const Duration(milliseconds: 900),
        () => mounted ? setState(() => _loading = false) : null);
  }

  @override
  void dispose() {
    _t?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    await Future<void>.delayed(const Duration(milliseconds: 700));
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: Neo.theme(),
      child: Scaffold(
        backgroundColor: Neo.bg,
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            color: Neo.accent,
            onRefresh: _refresh,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                _header(),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                      Neo.s24, Neo.s8, Neo.s24, Neo.s32),
                  sliver: SliverList.list(children: [
                    _loading ? const _KpiSkeleton() : const _TrustKpiCard(),
                    const SizedBox(height: Neo.s24),
                    if (_loading)
                      const _LineSkeleton(height: 96)
                    else
                      const _NextActionCard(),
                    const SizedBox(height: Neo.s24),
                    const _SectionLabel('Quick actions'),
                    const SizedBox(height: Neo.s12),
                    const _QuickActions(),
                    const SizedBox(height: Neo.s24),
                    const _SectionLabel('Recent activity'),
                    const SizedBox(height: Neo.s12),
                    if (_loading)
                      const _LineSkeleton(height: 180)
                    else
                      const _ActivityFeed(),
                    const SizedBox(height: Neo.s24),
                    if (!_loading) const _AiRecommendation(),
                  ]),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: const _NeoBottomNav(),
      ),
    );
  }

  Widget _header() => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
              Neo.s24, Neo.s16, Neo.s16, Neo.s8),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                    color: Neo.accentSoft, shape: BoxShape.circle),
                alignment: Alignment.center,
                child: const Text('S',
                    style: TextStyle(
                        fontFamily: Neo.family,
                        color: Neo.accent,
                        fontWeight: FontWeight.w600,
                        fontSize: 18)),
              ),
              const SizedBox(width: Neo.s12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Good evening', style: Neo.small),
                    Text('Swapnil', style: Neo.h3),
                  ],
                ),
              ),
              // A11y: the unread dot is color/shape-only → give it words.
              Semantics(
                label: 'Notifications, 1 unread',
                button: true,
                child: _IconButton(
                  icon: Icons.notifications_none_rounded,
                  badge: true,
                  onTap: () {},
                ),
              ),
            ],
          ),
        ),
      );
}

// ── KPI: Trust Index ─────────────────────────────────────────────────────
class _TrustKpiCard extends StatelessWidget {
  const _TrustKpiCard();

  @override
  Widget build(BuildContext context) {
    // A11y (audit §2.6): expose one composite label, not four fragments.
    return Semantics(
      container: true,
      label: 'Digital Trust Index, 712 of 1000, Gold band, '
          'up 8 this month, 138 points to Platinum',
      child: ExcludeSemantics(child: _card()),
    );
  }

  Widget _card() {
    return _NeoCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('DIGITAL TRUST INDEX', style: Neo.caption),
          const SizedBox(height: Neo.s8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('712', style: Neo.display),
              const SizedBox(width: Neo.s8),
              const Text('/ 1000', style: Neo.small),
              const Spacer(),
              _Pill(text: 'Gold', color: Neo.accent),
            ],
          ),
          const SizedBox(height: Neo.s16),
          // Absolute position on 0–1000, with a tick at the Platinum
          // threshold (850) so the goal is visual (Goal-Gradient, audit §2.CI).
          LayoutBuilder(
            builder: (context, c) => Stack(
              alignment: Alignment.centerLeft,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: const LinearProgressIndicator(
                    value: 0.712,
                    minHeight: 6,
                    backgroundColor: Neo.divider,
                    valueColor: AlwaysStoppedAnimation(Neo.accent),
                  ),
                ),
                Positioned(
                  left: c.maxWidth * 0.85 - 1,
                  child: Container(
                      width: 2, height: 12, color: Neo.text2),
                ),
              ],
            ),
          ),
          const SizedBox(height: Neo.s12),
          Row(
            children: const [
              Icon(Icons.trending_up_rounded, size: 16, color: Neo.success),
              SizedBox(width: Neo.s4),
              Text('Up 8 this month',
                  style: TextStyle(
                      fontFamily: Neo.family,
                      fontSize: 14,
                      color: Neo.success,
                      fontWeight: FontWeight.w500)),
              SizedBox(width: Neo.s8),
              Text('· 138 to Platinum', style: Neo.small),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Recommended next action (AI insight) ────────────────────────────────
class _NextActionCard extends StatelessWidget {
  const _NextActionCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Neo.surface,
        borderRadius: BorderRadius.circular(Neo.rLg),
        border: Border.all(color: Neo.accent.withValues(alpha: 0.35)),
      ),
      padding: const EdgeInsets.all(Neo.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.auto_awesome_rounded, size: 18, color: Neo.accent),
              SizedBox(width: Neo.s8),
              Text('RECOMMENDED FOR YOU',
                  style: TextStyle(
                      fontFamily: Neo.family,
                      fontSize: 12,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w600,
                      color: Neo.accent)),
            ],
          ),
          const SizedBox(height: Neo.s12),
          const Text('Reconnect with Rohan Mehta', style: Neo.h3),
          const SizedBox(height: Neo.s4),
          const Text(
            'Your strongest tie has gone quiet for 44 days. A short note now '
            'keeps a ₹2L+ relationship warm.',
            style: Neo.small,
          ),
          const SizedBox(height: Neo.s16),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: () {},
                  child: const Text('Draft a message'),
                ),
              ),
              const SizedBox(width: Neo.s12),
              _TextAction(label: 'Later', onTap: () {}),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Quick actions ────────────────────────────────────────────────────────
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  static const _items = [
    (Icons.forum_outlined, 'Ask / Offer'),
    (Icons.card_giftcard_outlined, 'Refer'),
    (Icons.podcasts_outlined, 'Briefing'),
    (Icons.card_membership_outlined, 'Invite'),
  ];

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final (icon, label) in _items) ...[
          Expanded(child: _QuickAction(icon: icon, label: label)),
          if (label != _items.last.$2) const SizedBox(width: Neo.s12),
        ],
      ],
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Neo.surface,
      borderRadius: BorderRadius.circular(Neo.rMd),
      child: InkWell(
        borderRadius: BorderRadius.circular(Neo.rMd),
        onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: Neo.s16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(Neo.rMd),
            border: Border.all(color: Neo.divider),
          ),
          child: Column(
            children: [
              Icon(icon, color: Neo.accent, size: 22),
              const SizedBox(height: Neo.s8),
              Text(label,
                  style: const TextStyle(
                      fontFamily: Neo.family,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Neo.text)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Recent activity ──────────────────────────────────────────────────────
class _ActivityFeed extends StatelessWidget {
  const _ActivityFeed();

  static const _items = [
    (Icons.verified_rounded, Neo.success, 'Referral settled',
        'Dr. Arvind Shetty · +₹500 · trust +6', '2h'),
    (Icons.handshake_outlined, Neo.accent, 'New vouch',
        'Priya Sharma vouched for you', '1d'),
    (Icons.forum_outlined, Neo.warning, 'Ask matched',
        'Your CFO intro request — 2 people can help', '2d'),
  ];

  @override
  Widget build(BuildContext context) {
    return _NeoCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < _items.length; i++) ...[
            Padding(
              padding: const EdgeInsets.all(Neo.s16),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                        color: _items[i].$2.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(Neo.rSm)),
                    child: Icon(_items[i].$1, size: 18, color: _items[i].$2),
                  ),
                  const SizedBox(width: Neo.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_items[i].$3, style: Neo.bodyStrong),
                        const SizedBox(height: 2),
                        Text(_items[i].$4, style: Neo.small),
                      ],
                    ),
                  ),
                  Text(_items[i].$5, style: Neo.caption),
                ],
              ),
            ),
            if (i != _items.length - 1)
              const Divider(height: 1, color: Neo.divider, indent: Neo.s16,
                  endIndent: Neo.s16),
          ],
        ],
      ),
    );
  }
}

// ── AI recommendation ────────────────────────────────────────────────────
class _AiRecommendation extends StatelessWidget {
  const _AiRecommendation();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          color: Neo.accentSoft, borderRadius: BorderRadius.circular(Neo.rLg)),
      padding: const EdgeInsets.all(Neo.s20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: const [
            Icon(Icons.insights_rounded, size: 18, color: Neo.accent),
            SizedBox(width: Neo.s8),
            Text('AI summary',
                style: TextStyle(
                    fontFamily: Neo.family,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Neo.accent)),
          ]),
          const SizedBox(height: Neo.s8),
          const Text(
            '3 open campaigns near you match your network. Acting on the '
            'clinic and CA campaigns could earn ~₹6,000 this week.',
            style: Neo.body,
          ),
          const SizedBox(height: Neo.s12),
          _TextAction(label: 'See matches →', onTap: () {}),
        ],
      ),
    );
  }
}

// ── Shared neo components ────────────────────────────────────────────────
class _NeoCard extends StatelessWidget {
  const _NeoCard({required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding ?? const EdgeInsets.all(Neo.s20),
      decoration: BoxDecoration(
        color: Neo.surface,
        borderRadius: BorderRadius.circular(Neo.rLg),
        boxShadow: Neo.shadow,
      ),
      child: child,
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: Neo.bodyStrong);
}

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: Neo.s12, vertical: Neo.s4),
        decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(999)),
        child: Text(text,
            style: TextStyle(
                fontFamily: Neo.family,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color)),
      );
}

class _TextAction extends StatelessWidget {
  const _TextAction({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => TextButton(
        onPressed: onTap,
        style: TextButton.styleFrom(
            foregroundColor: Neo.accent, textStyle: Neo.bodyStrong),
        child: Text(label),
      );
}

class _IconButton extends StatelessWidget {
  const _IconButton(
      {required this.icon, required this.onTap, this.badge = false});
  final IconData icon;
  final VoidCallback onTap;
  final bool badge;
  @override
  Widget build(BuildContext context) => SizedBox(
        width: 44,
        height: 44,
        child: Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
                onPressed: onTap, icon: Icon(icon, color: Neo.text, size: 24)),
            if (badge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                        color: Neo.error,
                        shape: BoxShape.circle,
                        border: Border.all(color: Neo.bg, width: 1.5))),
              ),
          ],
        ),
      );
}

// Skeletons
class _KpiSkeleton extends StatelessWidget {
  const _KpiSkeleton();
  @override
  Widget build(BuildContext context) => _NeoCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            _Shimmer(width: 120, height: 12),
            SizedBox(height: Neo.s12),
            _Shimmer(width: 160, height: 36),
            SizedBox(height: Neo.s16),
            _Shimmer(width: double.infinity, height: 6),
          ],
        ),
      );
}

class _LineSkeleton extends StatelessWidget {
  const _LineSkeleton({required this.height});
  final double height;
  @override
  Widget build(BuildContext context) => _NeoCard(
      child: _Shimmer(width: double.infinity, height: height - 40));
}

class _Shimmer extends StatefulWidget {
  const _Shimmer({required this.width, required this.height});
  final double width;
  final double height;
  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1100))
    ..repeat(reverse: true);
  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _c,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: Color.lerp(Neo.divider, const Color(0xFFF3F4F6), _c.value),
            borderRadius: BorderRadius.circular(Neo.rSm),
          ),
        ),
      );
}

class _NeoBottomNav extends StatelessWidget {
  const _NeoBottomNav();

  static const _tabs = [
    (Icons.grid_view_rounded, 'Home'),
    (Icons.hub_outlined, 'Network'),
    (Icons.add_circle_outline, 'Act'),
    (Icons.groups_outlined, 'Communities'),
    (Icons.person_outline_rounded, 'You'),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Neo.surface,
        border: Border(top: BorderSide(color: Neo.divider)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              for (var i = 0; i < _tabs.length; i++)
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(_tabs[i].$1,
                        size: 24, color: i == 0 ? Neo.accent : Neo.text2),
                    const SizedBox(height: 3),
                    Text(_tabs[i].$2,
                        style: TextStyle(
                            fontFamily: Neo.family,
                            fontSize: 11,
                            fontWeight:
                                i == 0 ? FontWeight.w600 : FontWeight.w400,
                            color: i == 0 ? Neo.accent : Neo.text2)),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
