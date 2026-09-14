import '../domain/privacy_finding.dart';

class DetectionRequest {
  const DetectionRequest({
    required this.text,
    required this.profileKey,
    required this.scopeKey,
    required this.scanLanguage,
    required this.entities,
    required this.confidenceThreshold,
  });

  final String text;
  final String profileKey;
  final String scopeKey;

  /// Detector/document language. This is not the app-interface language.
  final String scanLanguage;
  final List<String> entities;
  final double confidenceThreshold;
}

abstract interface class DetectionEngine {
  Future<List<PrivacyFinding>> analyze(DetectionRequest request);
}
