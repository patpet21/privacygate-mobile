import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/privacy_finding.dart';
import 'package:privacygate/core/protection/privacy_gate_protector.dart';

void main() {
  const protector = PrivacyGateProtector();

  test('contract: reversible token shape matches Desktop base contract', () {
    const text = 'Email jane@example.com';
    const finding = PrivacyFinding(
      findingId: 'email-1',
      entityType: 'EMAIL_ADDRESS',
      text: 'jane@example.com',
      start: 6,
      end: 22,
      score: 1,
    );

    final result = protector.protect(text, const [finding]);

    expect(result.protectedText, 'Email [[PG_EMAIL_ADDRESS_001]]');
    expect(result.mappings.single.originalText, 'jane@example.com');
    expect(protector.restore(result.protectedText, result.mappings), text);
  });

  test('contract: repeated value reuses the same token', () {
    const text = 'jane@example.com then jane@example.com';
    const findings = [
      PrivacyFinding(
        findingId: 'email-1',
        entityType: 'EMAIL_ADDRESS',
        text: 'jane@example.com',
        start: 0,
        end: 16,
        score: 1,
      ),
      PrivacyFinding(
        findingId: 'email-2',
        entityType: 'EMAIL_ADDRESS',
        text: 'jane@example.com',
        start: 22,
        end: 38,
        score: 1,
      ),
    ];

    final result = protector.protect(text, findings);

    expect(result.mappings, hasLength(1));
    expect(
      result.protectedText,
      '[[PG_EMAIL_ADDRESS_001]] then [[PG_EMAIL_ADDRESS_001]]',
    );
  });

  test('contract: redact and generic modes match Desktop outputs', () {
    const text = 'Value ABC-1234';
    const finding = PrivacyFinding(
      findingId: 'id-1',
      entityType: 'CUSTOMER_ID',
      text: 'ABC-1234',
      start: 6,
      end: 14,
      score: 1,
    );

    final redacted = protector.protect(
      text,
      const [finding],
      replacementMode: 'redact',
    );
    final generic = protector.protect(
      text,
      const [finding],
      replacementMode: 'generic',
    );

    expect(redacted.protectedText, 'Value [REDACTED]');
    expect(redacted.mappings, isEmpty);
    expect(generic.protectedText, 'Value [[CUSTOMER_ID]]');
    expect(generic.mappings, isEmpty);
  });

  test('contract: mask keeps final four alphanumeric characters', () {
    const text = 'ID AB-123456';
    const finding = PrivacyFinding(
      findingId: 'id-1',
      entityType: 'CUSTOMER_ID',
      text: 'AB-123456',
      start: 3,
      end: 12,
      score: 1,
    );

    final result = protector.protect(
      text,
      const [finding],
      replacementMode: 'mask',
    );

    expect(result.protectedText, 'ID **-**3456');
    expect(result.mappings, isEmpty);
  });
}
