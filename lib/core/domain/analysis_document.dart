import 'ocr.dart';
import 'page_content.dart';

class AnalysisDocument {
  const AnalysisDocument({
    required this.sourceKind,
    required this.pages,
    this.sourcePath,
    this.ocrPages = const [],
  });

  final String sourceKind;
  final List<PageContent> pages;
  final String? sourcePath;
  final List<OcrPageLayout> ocrPages;

  bool get hasText => pages.any((page) => page.text.trim().isNotEmpty);
}
