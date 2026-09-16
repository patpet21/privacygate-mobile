import '../desktop_link/desktop_link_client.dart';
import '../domain/privacy_finding.dart';
import 'detection_engine.dart';

class DesktopLinkDetectionEngine implements DetectionEngine {
  const DesktopLinkDetectionEngine(this.client);
  final DesktopLinkClient client;

  @override
  Future<List<PrivacyFinding>> analyze(DetectionRequest request) =>
      client.analyze(request);
}
