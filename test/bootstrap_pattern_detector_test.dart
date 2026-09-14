import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/bootstrap_pattern_detector.dart';
import 'package:privacygate/core/detection/detection_engine.dart';

void main() {
  test('bootstrap detector finds an allowed email for shell validation', () async {
    const detector = BootstrapPatternDetector();
    final findings = await detector.analyze(
      const DetectionRequest(
        text: 'Contact jane@example.com',
        profileKey: 'general_business',
        scopeKey: 'maximum',
        language: 'en',
        entities: ['EMAIL_ADDRESS'],
      ),
    );

    expect(findings, hasLength(1));
    expect(findings.single.entityType, 'EMAIL_ADDRESS');
    expect(findings.single.text, 'jane@example.com');
  });
}
