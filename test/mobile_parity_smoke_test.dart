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

    expect(find.text('Protected docs'), findsOneWidget);
    expect(find.text('Blocked actions'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('nav-library')));
    await tester.pumpAndSettle();
    expect(find.text('Mobile Offline'), findsOneWidget);
    expect(find.text('Restoreable'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.byKey(const ValueKey('nav-settings')));
    await tester.pumpAndSettle();
    expect(find.text('PrivacyGate controls'), findsOneWidget);
    expect(find.text('Account & Devices'), findsOneWidget);
    expect(find.text('AI & MCP'), findsOneWidget);
    expect(find.text('Policy Center'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
