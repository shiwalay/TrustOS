import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/design_system/tokens/colors.dart';
import '../../../../core/design_system/tokens/spacing.dart';

/// Step 2 — Tier-1 verification only (progressive disclosure: no KYC/GST at
/// onboarding — docs/10-ux-design.md W1 ③). STUBBED for the demo: any number
/// works and the OTP auto-fills after a second.
class VerifyStep extends StatefulWidget {
  const VerifyStep({required this.onNext, super.key});

  final VoidCallback onNext;

  @override
  State<VerifyStep> createState() => _VerifyStepState();
}

class _VerifyStepState extends State<VerifyStep> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  Timer? _autofill;

  bool _codeSent = false;
  bool _otpAutofilled = false;
  bool _verified = false;

  @override
  void dispose() {
    _autofill?.cancel();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendCode() {
    setState(() => _codeSent = true);
    // Demo mode: the "SMS" arrives after a second and types itself in.
    _autofill = Timer(const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {
        _otpController.text = '123456';
        _otpAutofilled = true;
      });
    });
  }

  void _verify() {
    if (_otpController.text.trim().length < 6) return;
    setState(() => _verified = true);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final positive =
        isDark ? EmberColors.positiveDark : EmberColors.positiveLight;

    return Padding(
      padding: const EdgeInsets.all(EmberSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: EmberSpacing.lg),
          Text('Verify your number', style: theme.textTheme.headlineMedium),
          const SizedBox(height: EmberSpacing.xs),
          Text(
            'Verification is the first brick of your Trust Index. '
            'One tier now — that is all we need.',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: EmberSpacing.lg),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            enabled: !_verified,
            decoration: const InputDecoration(
              labelText: 'Phone number',
              prefixText: '+91 ',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: EmberSpacing.md),
          if (!_codeSent)
            FilledButton(
              onPressed: _sendCode,
              child: const Text('Send code'),
            ),
          if (_codeSent && !_verified) ...[
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              decoration: const InputDecoration(
                labelText: '6-digit code',
                counterText: '',
                border: OutlineInputBorder(),
              ),
            ),
            if (_otpAutofilled) ...[
              const SizedBox(height: EmberSpacing.xxs),
              Text(
                'Demo mode — code auto-filled for you.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark
                      ? EmberColors.infoDark
                      : EmberColors.infoLight,
                ),
              ),
            ],
            const SizedBox(height: EmberSpacing.md),
            FilledButton(
              onPressed: _verify,
              child: const Text('Verify'),
            ),
          ],
          if (_verified) ...[
            const SizedBox(height: EmberSpacing.sm),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: EmberSpacing.xs,
                    vertical: EmberSpacing.xxs,
                  ),
                  decoration: BoxDecoration(
                    color: positive.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(EmberRadii.chip),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.verified_outlined, size: 16, color: positive),
                      const SizedBox(width: EmberSpacing.xxs),
                      Text(
                        'T1 verified',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: positive,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: EmberSpacing.xs),
            Text(
              'Higher verification unlocks more reach — later, not now.',
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            const Spacer(),
            FilledButton(
              onPressed: widget.onNext,
              child: const Text('Continue'),
            ),
            const SizedBox(height: EmberSpacing.md),
          ] else
            const Spacer(),
        ],
      ),
    );
  }
}
