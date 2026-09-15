import '../domain/analysis_document.dart';
import '../domain/page_content.dart';
import '../domain/privacy_finding.dart';

/// One-page request consumed by a local page detector.
///
/// This stays intentionally small: the document-level orchestration lives in
/// [DocumentDetectionEngine], mirroring Desktop PrivacyGate's service -> page
/// engine boundary.
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

/// Document-level detection request used by the Mobile Protect workflow.
class DocumentDetectionRequest {
  const DocumentDetectionRequest({
    required this.document,
    required this.profileKey,
    required this.scopeKey,
    required this.scanLanguage,
    required this.entities,
    required this.confidenceThreshold,
  });

  final AnalysisDocument document;
  final String profileKey;
  final String scopeKey;
  final String scanLanguage;
  final List<String> entities;
  final double confidenceThreshold;

  DetectionRequest forPage(PageContent page) => DetectionRequest(
        text: page.text,
        profileKey: profileKey,
        scopeKey: scopeKey,
        scanLanguage: scanLanguage,
        entities: entities,
        confidenceThreshold: confidenceThreshold,
      );
}

/// Page-local detector contract.
///
/// Desktop follows the same split: the application service iterates an
/// AnalysisDocument and the underlying PII engine analyzes one page at a time.
abstract interface class DetectionEngine {
  Future<List<PrivacyFinding>> analyze(DetectionRequest request);
}

/// Canonical document-level detector boundary used by Mobile Protect.
class DocumentDetectionEngine {
  const DocumentDetectionEngine(this.pageEngine);

  final DetectionEngine pageEngine;

  Future<List<PrivacyFinding>> analyze(DocumentDetectionRequest request) async {
    final findings = <PrivacyFinding>[];

    for (final page in request.document.pages) {
      if (page.text.trim().isEmpty) continue;
      final pageFindings = await pageEngine.analyze(request.forPage(page));
      for (var index = 0; index < pageFindings.length; index += 1) {
        final item = pageFindings[index];
        findings.add(
          PrivacyFinding(
            findingId:
                'p${page.pageNumber}-${item.start}-${item.end}-$index',
            entityType: item.entityType,
            text: item.text,
            start: item.start,
            end: item.end,
            score: item.score,
            pageNumber: page.pageNumber,
            context: item.context,
          ),
        );
      }
    }

    findings.sort((a, b) {
      final pageOrder = a.pageNumber.compareTo(b.pageNumber);
      if (pageOrder != 0) return pageOrder;
      final startOrder = a.start.compareTo(b.start);
      return startOrder != 0 ? startOrder : a.end.compareTo(b.end);
    });
    return List.unmodifiable(findings);
  }
}
