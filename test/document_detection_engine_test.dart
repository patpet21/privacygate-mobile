import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/detection/bootstrap_pattern_detector.dart';
import 'package:privacygate/core/detection/detection_engine.dart';
import 'package:privacygate/core/domain/analysis_document.dart';
import 'package:privacygate/core/domain/page_content.dart';

void main() {
  test('document detector preserves page-local offsets and unique Desktop-style ids', () async {
    const detector = DocumentDetectionEngine(BootstrapPatternDetector());
    const document = AnalysisDocument(
      sourceKind: 'pdf',
      sourcePath: 'sample.pdf',
      pages: [
        PageContent(pageNumber: 1, text: 'jane@example.com', location: 'page-1'),
        PageContent(pageNumber: 2, text: 'jane@example.com', location: 'page-2'),
      ],
    );

    final findings = await detector.analyze(
      const DocumentDetectionRequest(
        document: document,
        profileKey: 'general_business',
        scopeKey: 'financial',
        scanLanguage: 'en',
        entities: ['EMAIL_ADDRESS'],
        confidenceThreshold: 0.35,
      ),
    );

    expect(findings, hasLength(2));
    expect(findings.map((item) => item.pageNumber), [1, 2]);
    expect(findings.map((item) => item.start), [0, 0]);
    expect(findings.map((item) => item.end), [16, 16]);
    expect(findings[0].findingId, 'p1-0-16-0');
    expect(findings[1].findingId, 'p2-0-16-0');
  });
}
