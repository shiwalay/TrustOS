import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustos/core/design_system/theme/app_theme.dart';
import 'package:trustos/features/referrals/domain/entities/referral.dart';
import 'package:trustos/features/referrals/presentation/controllers/referral_list_controller.dart';
import 'package:trustos/features/referrals/presentation/screens/my_referrals_screen.dart';

/// Controllers are overridden at the provider level; widgets are never
/// mocked (09-mobile-architecture.md §8).
class _FakeListController extends ReferralListController {
  _FakeListController(this._streamFactory);

  final Stream<List<Referral>> Function() _streamFactory;

  @override
  Stream<List<Referral>> build(String arg) => _streamFactory();
}

Referral _referral(String id, String name, ReferralStatus status) => Referral(
      id: id,
      campaignId: 'cmp_1',
      prospectName: name,
      prospectPhone: '+919876543210',
      note: 'Warm lead',
      status: status,
      updatedAt: DateTime.utc(2026, 7, 1),
    );

Widget _app(Stream<List<Referral>> Function() streamFactory) => ProviderScope(
      overrides: [
        referralListProvider.overrideWith(
          () => _FakeListController(streamFactory),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const MyReferralsScreen(campaignId: 'cmp_1'),
      ),
    );

void main() {
  testWidgets('loading state renders the list skeleton', (tester) async {
    final controller = StreamController<List<Referral>>();
    addTearDown(controller.close);

    await tester.pumpWidget(_app(() => controller.stream));

    expect(find.byType(ReferralListSkeleton), findsOneWidget);
  });

  testWidgets('data state renders tiles with status chips, '
      'pendingSync visibly marked', (tester) async {
    await tester.pumpWidget(_app(
      () => Stream.value([
        _referral('ref_1', 'Dev Patel', ReferralStatus.pendingSync),
        _referral('ref_2', 'Meera Iyer', ReferralStatus.submitted),
        _referral('ref_3', 'Vikram Rao', ReferralStatus.converted),
      ]),
    ));
    await tester.pump(); // stream emission → AsyncData

    expect(find.text('Dev Patel'), findsOneWidget);
    expect(find.text('Pending sync'), findsOneWidget);
    expect(find.text('Submitted'), findsOneWidget);
    expect(find.text('Converted'), findsOneWidget);
    expect(find.byType(ReferralListSkeleton), findsNothing);
  });

  testWidgets('empty data shows the designed empty state', (tester) async {
    await tester.pumpWidget(_app(() => Stream.value(const [])));
    await tester.pump();

    expect(find.text('Referrals you submit appear here'), findsOneWidget);
  });

  testWidgets('error state shows plain-language message with retry',
      (tester) async {
    await tester.pumpWidget(
      _app(() => Stream.error(Exception('boom'))),
    );
    await tester.pump();

    expect(find.text("Couldn't load referrals"), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Retry'), findsOneWidget);
    // Raw exception text must never surface (10-ux-design.md §7).
    expect(find.textContaining('boom'), findsNothing);
  });
}
