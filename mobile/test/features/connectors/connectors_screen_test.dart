import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trustos/features/connectors/presentation/screens/connectors_screen.dart';

void main() {
  Future<void> pump(WidgetTester t) async {
    // Tall viewport so the whole (lazy) ListView is laid out at once.
    t.view.physicalSize = const Size(400, 5200);
    t.view.devicePixelRatio = 1.0;
    addTearDown(t.view.resetPhysicalSize);
    addTearDown(t.view.resetDevicePixelRatio);
    await t.pumpWidget(const MaterialApp(home: ConnectorsScreen()));
  }

  testWidgets('problem-first discovery lists verified connectors', (t) async {
    await pump(t);
    expect(find.text('Need a factory?'), findsOneWidget);
    expect(find.text('Need investors?'), findsOneWidget);
    expect(find.textContaining('Verified Connector · Manufacturing'),
        findsOneWidget);
    expect(find.text('Request a trusted intro'), findsWidgets);
  });

  testWidgets('requesting an intro confirms with the connector name',
      (t) async {
    await pump(t);
    await t.tap(find.text('Request a trusted intro').first);
    await t.pump();
    expect(find.textContaining('Intro requested from Vikram Rao'),
        findsOneWidget);
  });

  testWidgets('your standing shows an earned badge and an in-progress ladder',
      (t) async {
    await pump(t);
    expect(find.text('YOUR CONNECTOR STANDING'), findsOneWidget);
    expect(find.text('Verified Connector'), findsWidgets); // earned status pill
    expect(find.textContaining('2 more settled intros'), findsOneWidget);
  });
}
