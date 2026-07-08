import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustos/features/board/presentation/screens/board_screen.dart';

void main() {
  Future<void> pump(WidgetTester t) async {
    t.view.physicalSize = const Size(1080, 2400);
    t.view.devicePixelRatio = 3.0;
    addTearDown(t.view.resetPhysicalSize);
    await t.pumpWidget(const MaterialApp(home: BoardScreen()));
  }

  testWidgets('shows asks and offers with distinct badges', (t) async {
    await pump(t);
    expect(find.text('ASK'), findsWidgets);
    expect(find.text('OFFER'), findsWidgets);
    expect(find.textContaining('Warm intro to a CFO'), findsOneWidget);
  });

  testWidgets('filtering to Offers hides asks', (t) async {
    await pump(t);
    await t.tap(find.text('Offers'));
    await t.pumpAndSettle();
    expect(find.text('ASK'), findsNothing);
    expect(find.text('OFFER'), findsWidgets);
  });

  testWidgets('responding to an ask flips the card to a confirmed state',
      (t) async {
    await pump(t);
    // First card is an ask → primary action "I can help".
    await t.tap(find.text('I can help').first);
    await t.pump();
    expect(find.text('You offered to help'), findsOneWidget);
  });

  testWidgets('pushing relays to a contact and marks you the connector',
      (t) async {
    await pump(t);
    await t.tap(find.text('Push').first);
    await t.pumpAndSettle();
    // Relay sheet lists suggested contacts.
    expect(find.text('Push to someone who fits'), findsOneWidget);
    await t.tap(find.text('Rohan Mehta'));
    await t.pumpAndSettle();
    expect(find.textContaining('you’re the connector'), findsOneWidget);
  });
}
