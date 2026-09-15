import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/desktop_rule_detector.dart';
import 'package:privacygate/core/detection/detection_engine.dart';

void main() {
  const detector = DesktopRuleDetector();

  test('Desktop fixture EN-FINANCIAL-001: detects bank account value only', () async {
    final findings = await detector.analyze(
      const DetectionRequest(
        text: 'Account number: 8310722758',
        profileKey: 'general_business',
        scopeKey: 'financial',
        scanLanguage: 'en',
        entities: ['US_BANK_NUMBER'],
        confidenceThreshold: 0.35,
      ),
    );

    expect(findings, hasLength(1));
    expect(findings.single.entityType, 'US_BANK_NUMBER');
    expect(findings.single.text, '8310722758');
    expect(findings.single.start, 16);
    expect(findings.single.end, 26);
  });

  test('Desktop fixture EN-FINANCIAL-008: specific routing number wins', () async {
    final findings = await detector.analyze(
      const DetectionRequest(
        text: 'Routing number: 021000021',
        profileKey: 'general_business',
        scopeKey: 'financial',
        scanLanguage: 'en',
        entities: ['US_ROUTING_NUMBER', 'POSTAL_CODE'],
        confidenceThreshold: 0.35,
      ),
    );

    expect(findings, hasLength(1));
    expect(findings.single.entityType, 'US_ROUTING_NUMBER');
    expect(findings.single.text, '021000021');
  });

  test('protected PrivacyGate placeholders are never rescanned', () async {
    final findings = await detector.analyze(
      const DetectionRequest(
        text: '[[PG_US_BANK_NUMBER_001]]',
        profileKey: 'general_business',
        scopeKey: 'financial',
        scanLanguage: 'en',
        entities: ['US_BANK_NUMBER'],
        confidenceThreshold: 0.35,
      ),
    );

    expect(findings, isEmpty);
  });

  test('confidence threshold filters weaker deterministic rules', () async {
    final findings = await detector.analyze(
      const DetectionRequest(
        text: 'ZIP 10001',
        profileKey: 'general_business',
        scopeKey: 'financial',
        scanLanguage: 'en',
        entities: ['POSTAL_CODE'],
        confidenceThreshold: 0.90,
      ),
    );

    expect(findings, isEmpty);
  });
}
