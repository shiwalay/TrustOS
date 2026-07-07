import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/spacing.dart';
import '../widgets/aha_step.dart';
import '../widgets/import_step.dart';
import '../widgets/verify_step.dart';
import '../widgets/welcome_step.dart';

/// First-session activation flow — docs/10-ux-design.md §5.1 ("aha in
/// < 3 minutes"). Four steps: Welcome → Verify (T1 only, progressive
/// disclosure) → Contact import (consent-first, honest skip) → The Reveal.
///
/// Completing the flow flips [onboardedProvider]; the router redirect
/// (app/router/router.dart) then lands the user on Home.
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pageController = PageController();
  int _step = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    setState(() => _step = (_step + 1).clamp(0, 3));
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320), // Emphasized (10-ux §4.3)
      curve: Curves.easeInOutCubicEmphasized,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: EmberSpacing.sm),
              child: _StepDots(current: _step),
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                // Steps gate their own advancement; no swipe-skipping OTP.
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  WelcomeStep(onNext: _next),
                  VerifyStep(onNext: _next),
                  ImportStep(onNext: _next),
                  const AhaStep(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      label: 'Onboarding step ${current + 1} of 4',
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < 4; i++)
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin:
                  const EdgeInsets.symmetric(horizontal: EmberSpacing.xxs),
              width: i == current ? 20 : 8,
              height: 8,
              decoration: BoxDecoration(
                color: i <= current
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
        ],
      ),
    );
  }
}
