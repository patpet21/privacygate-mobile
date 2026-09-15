import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/app/privacy_gate_app.dart';

void main() {
  testWidgets('phone-width shell stays overflow-free across parity screens', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PrivacyGateApp());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('home-restore')));
    await tester.pumpAndSettle();
    expect(find.text('Restore your AI result'), findsOneWidget);
    expect(find.text('No local restore mapping yet'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pageBack();
    await tester.pumpAndSettle();

    var scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('Protected docs'),
      300,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('Protected docs'), findsOneWidget);
    expect(find.text('Blocked actions'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    expect(find.text('Mobile Offline'), findsOneWidget);
    expect(find.text('Restoreable'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpAndSettle();
    scrollable = find.byType(Scrollable).first;
    await tester.scrollUntilVisible(
      find.text('PrivacyGate controls'),
      350,
      scrollable: scrollable,
    );
    await tester.pumpAndSettle();
    expect(find.text('PrivacyGate controls'), findsOneWidget);
    expect(find.text('Account & Devices'), findsOneWidget);
    expect(find.text('AI & MCP'), findsOneWidget);
    expect(find.text('Policy Center'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('repeated tab switching does not trigger lifecycle assertions', (tester) async {
    await tester.binding.setSurfaceSize(const Size(360, 800));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const PrivacyGateApp());
    await tester.pumpAndSettle();

    const sequence = [
      'nav-protect',
      'nav-settings',
      'nav-library',
      'nav-home',
      'nav-activity',
      'nav-protect',
      'nav-home',
      'nav-settings',
      'nav-home',
    ];

    for (final key in sequence) {
      await tester.tap(find.byKey(ValueKey(key)));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull, reason: 'Tab switch failed at $key');
    }
  });
}
