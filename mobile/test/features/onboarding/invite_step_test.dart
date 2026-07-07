import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:trustos/core/session/legal_acceptance.dart';
import 'package:trustos/core/session/onboarding_state.dart';
import 'package:trustos/features/onboarding/presentation/widgets/invite_step.dart';

void main() {
  late SharedPreferences prefs;

  Future<void> pump(WidgetTester tester, VoidCallback onNext) async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
        child: MaterialApp(
          home: Scaffold(body: InviteStep(onNext: onNext)),
        ),
      ),
    );
  }

  testWidgets('redeeming a valid code reveals the vouch card and terms gate',
      (tester) async {
    await pump(tester, () {});

    await tester.enterText(find.byType(TextField), 'trust-demo');
    await tester.tap(find.text('Redeem invitation'));
    await tester.pump();

    expect(find.textContaining('Invited by Rohan Mehta'), findsOneWidget);
    expect(
        find.textContaining('I agree to the Terms of Service'), findsOneWidget);

    // Continue is gated until the terms box is checked.
    final continueBtn =
        tester.widget<FilledButton>(find.widgetWithText(FilledButton, 'Continue'));
    expect(continueBtn.onPressed, isNull);
  });

  testWidgets('agreeing logs the accepted version + timestamp and advances',
      (tester) async {
    var advanced = false;
    await pump(tester, () => advanced = true);

    await tester.enterText(find.byType(TextField), 'TRUST-DEMO');
    await tester.tap(find.text('Redeem invitation'));
    await tester.pump();

    await tester.tap(find.byType(Checkbox));
    await tester.pump();
    await tester.tap(find.widgetWithText(FilledButton, 'Continue'));
    await tester.pumpAndSettle();

    expect(advanced, isTrue);
    expect(LegalAcceptance.isCurrent(prefs), isTrue);
    expect(prefs.getString('legal.acceptedVersion'),
        LegalAcceptance.currentVersion);
    expect(prefs.getString('legal.acceptedAt'), isNotNull);
    // Timestamp parses and is UTC — the evidentiary record is well-formed.
    final at = DateTime.parse(prefs.getString('legal.acceptedAt')!);
    expect(at.isUtc, isTrue);
  });

  testWidgets('malformed codes show an error, not the gate', (tester) async {
    await pump(tester, () {});

    await tester.enterText(find.byType(TextField), 'HELLO');
    await tester.tap(find.text('Redeem invitation'));
    await tester.pump();

    expect(find.textContaining('does not look like'), findsOneWidget);
    expect(find.textContaining('I agree'), findsNothing);
  });
}
