import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/bootstrap_pattern_detector.dart';
import 'package:privacygate/core/protection/privacy_gate_protector.dart';
import 'package:privacygate/core/protection/protection_policy.dart';
import 'package:privacygate/features/protect/protect_controller.dart';

void main() {
  test('changing scan language invalidates findings and requires a fresh scan', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const BootstrapPatternDetector(),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    await controller.analyze('Contact jane@example.com');
    expect(controller.findings, isNotEmpty);

    policy.setScanLanguage('it');
    expect(controller.findings, isEmpty);
    expect(controller.result, isNull);

    controller.dispose();
    policy.dispose();
  });

  test('protected text is exportable only after the second scan passes', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const BootstrapPatternDetector(),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    await controller.analyze('Contact jane@example.com');
    await controller.protectAndVerify();

    expect(controller.result, isNotNull);
    expect(controller.verificationPerformed, isTrue);
    expect(controller.residualFindings, isEmpty);
    expect(controller.exportVerified, isTrue);

    controller.dispose();
    policy.dispose();
  });
}
