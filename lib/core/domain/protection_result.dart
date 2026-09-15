import 'page_content.dart';
import 'privacy_finding.dart';
import 'protected_span.dart';
import 'replacement_mapping.dart';

class ProtectionResult {
  const ProtectionResult({
    required this.protectedPages,
    this.appliedFindings = const [],
    this.mappings = const [],
    this.protectedSpans = const [],
    this.replacementMode = 'reversible',
  });

  final List<PageContent> protectedPages;
  final List<PrivacyFinding> appliedFindings;
  final List<ReplacementMapping> mappings;
  final List<ProtectedSpan> protectedSpans;
  final String replacementMode;

  /// Backward-compatible single-string view used by the current Mobile UI.
  String get protectedText => combinedText;

  String get combinedText {
    if (protectedPages.length == 1) return protectedPages.first.text;
    return protectedPages
        .map((page) => '--- Page ${page.pageNumber} ---\n${page.text}')
        .join('\n\n');
  }

  /// Return replacement spans adjusted to offsets in [combinedText].
  List<ProtectedSpan> get combinedSpans {
    if (protectedPages.length == 1) return protectedSpans;

    final spansByPage = <int, List<ProtectedSpan>>{};
    for (final span in protectedSpans) {
      spansByPage.putIfAbsent(span.pageNumber, () => <ProtectedSpan>[]).add(span);
    }

    final adjusted = <ProtectedSpan>[];
    var cursor = 0;
    for (var pageIndex = 0; pageIndex < protectedPages.length; pageIndex += 1) {
      final page = protectedPages[pageIndex];
      final prefix = '--- Page ${page.pageNumber} ---\n';
      final pageOffset = cursor + prefix.length;
      for (final span in spansByPage[page.pageNumber] ?? const <ProtectedSpan>[]) {
        adjusted.add(
          ProtectedSpan(
            pageNumber: span.pageNumber,
            start: pageOffset + span.start,
            end: pageOffset + span.end,
            entityType: span.entityType,
            findingId: span.findingId,
            replacementText: span.replacementText,
          ),
        );
      }
      cursor += prefix.length + page.text.length;
      if (pageIndex < protectedPages.length - 1) cursor += 2;
    }
    return List.unmodifiable(adjusted);
  }
}
