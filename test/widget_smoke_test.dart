import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/app/privacy_gate_app.dart';

void main() {
  testWidgets('PrivacyGate renders approved mobile shell and Protect flow',
      (tester) async {
    await tester.pumpWidget(const PrivacyGateApp());

    expect(find.text('Your privacy, your control.'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-protect')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-library')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-activity')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-protect')));
    await tester.pumpAndSettle();

    expect(find.text('Document workspace'), findsOneWidget);
    expect(find.text('Paste text'), findsWidgets);
    expect(find.text('Original document'), findsOneWidget);
    expect(find.text('Protected document'), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-options')), findsOneWidget);

    final protectScroll = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('continue-scan')),
      300,
      scrollable: protectScroll,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('continue-scan')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
