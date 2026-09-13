import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/bootstrap_pattern_detector.dart';

void main() {
  test('bootstrap detector finds an email for shell validation', () async {
    const detector = BootstrapPatternDetector();
    final findings = await detector.analyze('Contact jane@example.com');

    expect(findings, hasLength(1));
    expect(findings.single.entityType, 'EMAIL_ADDRESS');
    expect(findings.single.text, 'jane@example.com');
  });
}
