import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/app/privacy_gate_app.dart';

void main() {
  testWidgets('PrivacyGate Protect workspace renders Desktop-parity controls', (tester) async {
    await tester.pumpWidget(const PrivacyGateApp());

    expect(find.text('PrivacyGate'), findsOneWidget);
    expect(find.text('Protect a document'), findsOneWidget);
    expect(find.text('Scan language'), findsOneWidget);
    expect(find.text('Scan for sensitive data'), findsOneWidget);
    expect(find.text('Industry profile'), findsOneWidget);
    expect(find.text('Protection scope'), findsOneWidget);
  });
}
