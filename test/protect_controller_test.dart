import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/bootstrap_pattern_detector.dart';
import 'package:privacygate/core/detection/detection_engine.dart';
import 'package:privacygate/core/protection/privacy_gate_protector.dart';
import 'package:privacygate/core/protection/protection_policy.dart';
import 'package:privacygate/features/protect/protect_controller.dart';
import 'package:privacygate/features/protect/protect_state.dart';

void main() {
  test('changing scan language invalidates findings and requires a fresh scan', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
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
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
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

  test('manual finding overrides an overlapping automatic detection', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    await controller.analyze('Contact jane@example.com');
    expect(controller.findings.single.entityType, 'EMAIL_ADDRESS');

    controller.addManualFinding('jane@example.com', 'Custom sensitive');

    expect(controller.findings, hasLength(1));
    final manual = controller.findings.single;
    expect(manual.findingId, startsWith('manual-p1-'));
    expect(manual.entityType, 'CUSTOM_SENSITIVE');
    expect(controller.selectedFindingIds, contains(manual.findingId));

    await controller.protectAndVerify();
    expect(
      controller.result!.protectedText,
      'Contact [[PG_CUSTOM_SENSITIVE_001]]',
    );

    controller.dispose();
    policy.dispose();
  });

  test('manual finding and its selection survive policy changes and rescans', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );
    const text = 'Contact jane@example.com about Project Apollo';

    await controller.analyze(text);
    controller.addManualFinding('Project Apollo', 'PROJECT_NAME');
    final manualId = controller.findings
        .singleWhere((item) => item.findingId.startsWith('manual-'))
        .findingId;
    controller.setSelected(manualId, false);

    policy.setScanLanguage('it');
    expect(
      controller.findings.map((item) => item.findingId),
      contains(manualId),
    );
    expect(controller.selectedFindingIds, isNot(contains(manualId)));

    await controller.analyze(text);
    expect(
      controller.findings.map((item) => item.findingId),
      contains(manualId),
    );
    expect(controller.selectedFindingIds, isNot(contains(manualId)));

    controller.dispose();
    policy.dispose();
  });

  test('manual findings are discarded when the source text changes', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    await controller.analyze('Project Apollo owner jane@example.com');
    controller.addManualFinding('Project Apollo', 'PROJECT_NAME');
    expect(
      controller.findings.any((item) => item.findingId.startsWith('manual-')),
      isTrue,
    );

    await controller.analyze('Contact bob@example.com');
    expect(
      controller.findings.any((item) => item.findingId.startsWith('manual-')),
      isFalse,
    );

    controller.dispose();
    policy.dispose();
  });

  test('manual ranges cannot overlap and an exact range can be relabeled', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    await controller.analyze('Alpha Beta Gamma');
    controller.addManualFindingRange(
      start: 0,
      end: 10,
      entityType: 'FIRST_LABEL',
    );
    controller.addManualFindingRange(
      start: 6,
      end: 16,
      entityType: 'SECOND_LABEL',
    );

    expect(controller.findings, hasLength(1));
    expect(controller.findings.single.entityType, 'FIRST_LABEL');

    controller.addManualFindingRange(
      start: 0,
      end: 10,
      entityType: 'RENAMED_LABEL',
    );

    expect(controller.findings, hasLength(1));
    expect(controller.findings.single.entityType, 'RENAMED_LABEL');
    expect(
      controller.selectedFindingIds,
      contains(controller.findings.single.findingId),
    );

    controller.dispose();
    policy.dispose();
  });

  test('workflow state moves from source to review to protected', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    expect(controller.phase, ProtectPhase.source);
    expect(controller.operation, ProtectOperation.idle);
    expect(controller.analyzing, isFalse);
    expect(controller.verificationRunning, isFalse);

    await controller.analyze('Contact jane@example.com');
    expect(controller.phase, ProtectPhase.review);
    expect(controller.operation, ProtectOperation.idle);

    await controller.protectAndVerify();
    expect(controller.phase, ProtectPhase.protected);
    expect(controller.operation, ProtectOperation.idle);
    expect(controller.exportVerified, isTrue);

    controller.dispose();
    policy.dispose();
  });

  test('changing policy returns protected workflow to source phase', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    await controller.analyze('Contact jane@example.com');
    await controller.protectAndVerify();
    expect(controller.phase, ProtectPhase.protected);

    policy.setScanLanguage('it');

    expect(controller.phase, ProtectPhase.source);
    expect(controller.operation, ProtectOperation.idle);
    expect(controller.result, isNull);

    controller.dispose();
    policy.dispose();
  });

  test('clear resets workflow state to source and idle', () async {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(BootstrapPatternDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );

    await controller.analyze('Contact jane@example.com');
    expect(controller.phase, ProtectPhase.review);

    controller.clear();

    expect(controller.phase, ProtectPhase.source);
    expect(controller.operation, ProtectOperation.idle);
    expect(controller.findings, isEmpty);
    expect(controller.result, isNull);

    controller.dispose();
    policy.dispose();
  });
}
