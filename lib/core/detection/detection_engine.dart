import '../domain/privacy_finding.dart';

class DetectionRequest {
  const DetectionRequest({
    required this.text,
    required this.profileKey,
    required this.scopeKey,
    required this.language,
    required this.entities,
  });

  final String text;
  final String profileKey;
  final String scopeKey;
  final String language;
  final List<String> entities;
}

abstract interface class DetectionEngine {
  Future<List<PrivacyFinding>> analyze(DetectionRequest request);
}
