import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/detection_engine.dart';
import 'package:privacygate/core/detection/detection_engine_router.dart';
import 'package:privacygate/core/domain/privacy_finding.dart';

void main() {
  const request = DetectionRequest(
    text: 'Jane Smith jane@example.com',
    profileKey: 'general_business',
    scopeKey: 'maximum',
    scanLanguage: 'en',
    entities: ['PERSON', 'EMAIL_ADDRESS'],
    confidenceThreshold: 0.35,
  );

  test('router prefers Desktop when paired engine is available', () async {
    final router = DetectionEngineRouter(
      mobileBasic: const _Detector('EMAIL_ADDRESS'),
      desktop: const _Detector('PERSON'),
      desktopAvailable: () async => true,
    );

    final findings = await router.analyze(request);

    expect(router.lastUsed, DetectionEngineKind.desktop);
    expect(findings.single.entityType, 'PERSON');
  });

  test('router uses Enhanced when Desktop is unavailable', () async {
    final router = DetectionEngineRouter(
      mobileBasic: const _Detector('EMAIL_ADDRESS'),
      desktop: const _Detector('PERSON'),
      desktopAvailable: () async => false,
      mobileEnhanced: const _Detector('ORGANIZATION'),
      mobileEnhancedAvailable: () async => true,
    );

    final findings = await router.analyze(request);

    expect(router.lastUsed, DetectionEngineKind.mobileEnhanced);
    expect(findings.single.entityType, 'ORGANIZATION');
  });

  test('router falls back to Mobile Basic when Desktop disappears', () async {
    final router = DetectionEngineRouter(
      mobileBasic: const _Detector('EMAIL_ADDRESS'),
      desktop: _UnavailableDetector(),
      desktopAvailable: () async => true,
    );

    final findings = await router.analyze(request);

    expect(router.lastUsed, DetectionEngineKind.mobileBasic);
    expect(findings.single.entityType, 'EMAIL_ADDRESS');
  });

  test('router does not hide non-availability Desktop failures', () async {
    final router = DetectionEngineRouter(
      mobileBasic: const _Detector('EMAIL_ADDRESS'),
      desktop: _BrokenDetector(),
      desktopAvailable: () async => true,
    );

    await expectLater(
      router.analyze(request),
      throwsA(isA<StateError>()),
    );
  });
}

class _Detector implements DetectionEngine {
  const _Detector(this.entityType);

  final String entityType;

  @override
  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async => [
        PrivacyFinding(
          findingId: 'test',
          entityType: entityType,
          text: request.text.substring(0, 4),
          start: 0,
          end: 4,
          score: 0.9,
          context: request.text,
        ),
      ];
}

class _UnavailableDetector implements DetectionEngine {
  @override
  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async {
    throw const DetectionEngineUnavailableException();
  }
}

class _BrokenDetector implements DetectionEngine {
  @override
  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async {
    throw StateError('protocol mismatch');
  }
}
