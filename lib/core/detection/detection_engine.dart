import '../domain/privacy_finding.dart';

abstract interface class DetectionEngine {
  Future<List<PrivacyFinding>> analyze(String text);
}
