import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/app/privacy_gate_app.dart';

void main() {
  testWidgets('PrivacyGate mobile shell renders', (tester) async {
    await tester.pumpWidget(const PrivacyGateApp());

    expect(find.text('PrivacyGate'), findsOneWidget);
    expect(find.text('Scan locally'), findsOneWidget);
  });
}
