import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/app/privacy_gate_app.dart';

void main() {
  testWidgets(
    'PrivacyGate renders approved mobile shell and Protect flow',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(const PrivacyGateApp());
      await tester.pumpAndSettle();

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
      expect(find.byKey(const ValueKey('scan-options')), findsOneWidget);
      expect(find.byKey(const ValueKey('workspace-selector')), findsOneWidget);
      expect(tester.takeException(), isNull);

      await tester.tap(find.byKey(const ValueKey('workspace-selector')));
      await tester.pumpAndSettle();
      expect(find.text('Choose workspace'), findsOneWidget);
      expect(find.text('PrivacyGate Personal'), findsOneWidget);
      expect(find.text('Enterprise organization'), findsOneWidget);
      await tester.tap(find.text('PrivacyGate Personal'));
      await tester.pumpAndSettle();

      final protectScroll = find.byType(ListView).first;
      expect(protectScroll, findsOneWidget);

      Future<void> reveal(Finder target) async {
        for (var i = 0; i < 12 && target.evaluate().isEmpty; i++) {
          await tester.drag(protectScroll, const Offset(0, -260));
          await tester.pumpAndSettle();
        }
        expect(target, findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      await reveal(find.text('Original document'));
      await reveal(find.text('Protected document'));
    },
  );
}
