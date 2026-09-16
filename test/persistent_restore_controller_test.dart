import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/desktop_rule_detector.dart';
import 'package:privacygate/core/detection/detection_engine.dart';
import 'package:privacygate/core/domain/library_document.dart';
import 'package:privacygate/core/domain/replacement_mapping.dart';
import 'package:privacygate/core/protection/privacy_gate_protector.dart';
import 'package:privacygate/core/protection/protection_policy.dart';
import 'package:privacygate/features/protect/protect_controller.dart';

void main() {
  test('controller restores a persisted Library record without the original session', () {
    final policy = ProtectionPolicy();
    final controller = ProtectController(
      detector: const DocumentDetectionEngine(DesktopRuleDetector()),
      protector: const PrivacyGateProtector(),
      policy: policy,
    );
    addTearDown(() {
      controller.dispose();
      policy.dispose();
    });

    final now = DateTime.utc(2026, 9, 15, 23, 45);
    final document = LibraryDocument(
      documentId: 'doc_saved_001',
      title: 'Saved safe copy',
      sourceKind: 'text',
      sourceName: 'Paste text',
      profileKey: 'general_business',
      protectedText: 'Hello [[PG_PERSON_001]]',
      findingsCount: 1,
      entityTypes: const ['PERSON'],
      labels: const [],
      replacementMode: 'reversible',
      createdAt: now,
      updatedAt: now,
      hasMapping: true,
    );

    controller.loadPersistedProtection(
      document,
      const [
        ReplacementMapping(
          token: '[[PG_PERSON_001]]',
          entityType: 'PERSON',
          originalText: 'Jane Doe',
        ),
      ],
    );

    expect(controller.restoringPersistedDocument, isTrue);
    expect(controller.activeLibraryDocument?.documentId, 'doc_saved_001');
    expect(controller.hasLocalRestoreMapping, isTrue);
    expect(controller.exportVerified, isTrue);
    expect(
      controller.restoreTextLocally('Hello [[PG_PERSON_001]]'),
      'Hello Jane Doe',
    );
  });
}
