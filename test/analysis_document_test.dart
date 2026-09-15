import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/analysis_document.dart';
import 'package:privacygate/core/domain/ocr.dart';
import 'package:privacygate/core/domain/page_content.dart';

void main() {
  test('contract: AnalysisDocument mirrors Desktop source metadata', () {
    const document = AnalysisDocument(
      sourceKind: 'pdf',
      sourcePath: '/local/example.pdf',
      pages: [
        PageContent(pageNumber: 1, text: 'Sensitive text', location: 'page-1'),
      ],
    );

    expect(document.sourceKind, 'pdf');
    expect(document.sourcePath, '/local/example.pdf');
    expect(document.pages.single.pageNumber, 1);
    expect(document.hasText, isTrue);
    expect(document.ocrPages, isEmpty);
  });

  test('contract: OCR layout range lookup mirrors Desktop domain behavior', () {
    const word = OcrTextRegion(
      text: 'Jane',
      start: 0,
      end: 4,
      confidence: 0.98,
      polygon: [(0.0, 0.0), (10.0, 0.0), (10.0, 5.0), (0.0, 5.0)],
    );
    const line = OcrTextRegion(
      text: 'Jane Doe',
      start: 0,
      end: 8,
      confidence: 0.95,
      polygon: [(0.0, 0.0), (20.0, 0.0), (20.0, 5.0), (0.0, 5.0)],
      level: 'line',
    );
    const layout = OcrPageLayout(
      pageNumber: 1,
      width: 100,
      height: 200,
      regions: [word, line],
    );

    expect(layout.regionsForRange(1, 3), [word]);
    expect(layout.regionsForRange(5, 7), [line]);
  });
}
