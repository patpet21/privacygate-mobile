import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/app/privacy_gate_app.dart';

void main() {
  testWidgets('PrivacyGate renders approved mobile shell and Protect flow', (tester) async {
    await tester.pumpWidget(const PrivacyGateApp());

    expect(find.text('Your privacy, your control.'), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-home')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-protect')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-library')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-activity')), findsOneWidget);
    expect(find.byKey(const ValueKey('nav-settings')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-protect')));
    await tester.pumpAndSettle();

    expect(find.text('Protect data'), findsOneWidget);
    expect(find.text('Import from'), findsOneWidget);
    expect(find.text('Paste text'), findsOneWidget);

    final protectScroll = find.byType(Scrollable).first;

    await tester.scrollUntilVisible(
      find.text('Protection profile'),
      350,
      scrollable: protectScroll,
    );
    await tester.pumpAndSettle();

    expect(find.text('Protection profile'), findsOneWidget);
    expect(find.byKey(const ValueKey('scan-options')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('continue-scan')),
      350,
      scrollable: protectScroll,
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('continue-scan')), findsOneWidget);
  });
}
