import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/protection/protection_policy.dart';
import 'package:privacygate/core/settings/privacy_gate_settings.dart';

void main() {
  test('Desktop-parity Protect defaults are document-scoped', () {
    final policy = ProtectionPolicy();

    expect(policy.profileKey, 'general_business');
    expect(policy.scopeKey, 'financial');
    expect(policy.scanLanguage, 'en');
    expect(policy.replacementMode, ReplacementMode.reversible);
    expect(policy.confidenceThreshold, 0.35);
  });

  test('scan language is an independent detector control', () {
    final policy = ProtectionPolicy();
    policy.setScanLanguage('it');

    expect(policy.scanLanguage, 'it');
    expect(policy.profileKey, 'general_business');
    expect(policy.scopeKey, 'financial');
  });
}
