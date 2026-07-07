import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/design_system/tokens/spacing.dart';
import '../../domain/failures.dart';
import '../../domain/repositories/referral_repository.dart';
import '../controllers/submit_referral_controller.dart';

/// Submit sheet (10-ux-design.md W8 + §2.4: verbs on an entity are sheets,
/// not screens, when the task takes < 30 s). Consent checkbox is a hard gate.
Future<void> showSubmitReferralSheet(BuildContext context, String campaignId) =>
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => SubmitReferralSheet(campaignId: campaignId),
    );

class SubmitReferralSheet extends ConsumerStatefulWidget {
  const SubmitReferralSheet({required this.campaignId, super.key});

  final String campaignId;

  @override
  ConsumerState<SubmitReferralSheet> createState() =>
      _SubmitReferralSheetState();
}

class _SubmitReferralSheetState extends ConsumerState<SubmitReferralSheet> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _noteController = TextEditingController();
  bool _consentConfirmed = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submitState =
        ref.watch(submitReferralControllerProvider(widget.campaignId));

    ref.listen(submitReferralControllerProvider(widget.campaignId),
        (previous, next) {
      final value = next.valueOrNull;
      if (value is SubmitQueued) {
        Navigator.of(context).pop();
        // Row-level "Pending sync" chip carries the state from here —
        // no premature "reward earned" messaging (queue-and-confirm).
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Referral queued — pending sync')),
        );
      }
    });

    final error = submitState.error;

    return Padding(
      padding: EdgeInsets.only(
        left: EmberSpacing.screenGutter,
        right: EmberSpacing.screenGutter,
        top: EmberSpacing.lg,
        bottom:
            MediaQuery.viewInsetsOf(context).bottom + EmberSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Submit a referral',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: EmberSpacing.md),
          TextField(
            controller: _nameController,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Prospect name'),
          ),
          const SizedBox(height: EmberSpacing.sm),
          TextField(
            controller: _phoneController,
            keyboardType: TextInputType.phone,
            decoration: const InputDecoration(
              labelText: 'Phone',
              hintText: '+91 98…',
            ),
          ),
          const SizedBox(height: EmberSpacing.sm),
          TextField(
            controller: _noteController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Context (why fit)'),
          ),
          const SizedBox(height: EmberSpacing.sm),
          // Consent is a hard requirement (W8 ⑥ — anti-spam is
          // trust-protective; maps to consentConfirmed in SubmitReferral).
          CheckboxListTile(
            value: _consentConfirmed,
            onChanged: (v) => setState(() => _consentConfirmed = v ?? false),
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            title: const Text(
              'The prospect knows I am referring them and agreed to be contacted',
            ),
          ),
          if (error is ReferralFailure) ...[
            const SizedBox(height: EmberSpacing.xs),
            Text(
              _failureCopy(error),
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: Theme.of(context).colorScheme.error),
            ),
          ],
          const SizedBox(height: EmberSpacing.md),
          FilledButton(
            onPressed: submitState.isLoading ? null : _submit,
            child: submitState.isLoading
                ? const SizedBox.square(
                    dimension: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Submit referral'),
          ),
        ],
      ),
    );
  }

  void _submit() {
    ref
        .read(submitReferralControllerProvider(widget.campaignId).notifier)
        .submit(
          SubmitReferralDraft(
            campaignId: widget.campaignId,
            prospectName: _nameController.text,
            prospectPhone: _phoneController.text,
            note: _noteController.text,
            consentConfirmed: _consentConfirmed,
          ),
        );
  }

  // Placeholder copy — real strings resolve l10n key referral.failure.<code>.
  String _failureCopy(ReferralFailure failure) => switch (failure.code) {
        'consent_required' => 'Please confirm the prospect has agreed.',
        'prospect_name_too_short' => 'Enter the prospect’s full name.',
        'invalid_phone' => 'Enter a valid phone number with country code.',
        _ => 'Could not submit — please review and try again.',
      };
}
