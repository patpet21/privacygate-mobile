import '../domain/analysis_document.dart';
import '../domain/page_content.dart';
import '../domain/privacy_finding.dart';
import '../domain/protected_span.dart';
import '../domain/protection_result.dart';
import '../domain/replacement_mapping.dart';
import '../settings/privacy_gate_settings.dart';

class PrivacyGateProtector {
  const PrivacyGateProtector();

  ProtectionResult protect(
    AnalysisDocument document,
    Iterable<PrivacyFinding> selected, {
    ReplacementMode replacementMode = ReplacementMode.reversible,
  }) {
    final findings = selected.toList()
      ..sort((a, b) {
        final pageOrder = a.pageNumber.compareTo(b.pageNumber);
        if (pageOrder != 0) return pageOrder;
        return a.start.compareTo(b.start);
      });
    _validateDocumentFindings(document, findings);

    final byPage = <int, List<PrivacyFinding>>{};
    for (final finding in findings) {
      byPage.putIfAbsent(finding.pageNumber, () => <PrivacyFinding>[]).add(finding);
    }

    final counters = <String, int>{};
    final tokenByValue = <String, String>{};
    final mappings = <String, ReplacementMapping>{};
    final replacements = <String, String>{};

    for (final finding in findings) {
      final replacement = switch (replacementMode) {
        ReplacementMode.redact => '[REDACTED]',
        ReplacementMode.generic => '[[${finding.entityType}]]',
        ReplacementMode.mask => _maskValue(finding.text),
        ReplacementMode.reversible => _reversibleToken(
            finding,
            counters,
            tokenByValue,
            mappings,
          ),
      };
      replacements[finding.findingId] = replacement;
    }

    final protectedPages = <PageContent>[];
    final protectedSpans = <ProtectedSpan>[];

    for (final page in document.pages) {
      final output = StringBuffer();
      var sourceCursor = 0;
      var protectedCursor = 0;
      final pageFindings = byPage[page.pageNumber] ?? const <PrivacyFinding>[];

      for (final finding in pageFindings) {
        final untouched = page.text.substring(sourceCursor, finding.start);
        output.write(untouched);
        protectedCursor += untouched.length;

        final replacement = replacements[finding.findingId]!;
        final spanStart = protectedCursor;
        output.write(replacement);
        protectedCursor += replacement.length;
        protectedSpans.add(
          ProtectedSpan(
            pageNumber: page.pageNumber,
            start: spanStart,
            end: protectedCursor,
            entityType: finding.entityType,
            findingId: finding.findingId,
            replacementText: replacement,
          ),
        );
        sourceCursor = finding.end;
      }

      output.write(page.text.substring(sourceCursor));
      protectedPages.add(
        PageContent(
          pageNumber: page.pageNumber,
          text: output.toString(),
          location: page.location,
        ),
      );
    }

    return ProtectionResult(
      protectedPages: List.unmodifiable(protectedPages),
      appliedFindings: List.unmodifiable(findings),
      mappings: List.unmodifiable(mappings.values),
      protectedSpans: List.unmodifiable(protectedSpans),
      replacementMode: replacementMode.wireValue,
    );
  }

  /// Compatibility adapter for the current Paste Text workflow.
  ProtectionResult protectText(
    String text,
    Iterable<PrivacyFinding> selected, {
    ReplacementMode replacementMode = ReplacementMode.reversible,
  }) {
    return protect(
      AnalysisDocument(
        sourceKind: 'text',
        pages: [PageContent(pageNumber: 1, text: text)],
      ),
      selected,
      replacementMode: replacementMode,
    );
  }

  String restore(String text, Iterable<ReplacementMapping> mappings) {
    var restored = text;
    final ordered = mappings.toList()
      ..sort((a, b) => b.token.length.compareTo(a.token.length));
    for (final mapping in ordered) {
      restored = restored.replaceAll(mapping.token, mapping.originalText);
    }
    return restored;
  }

  static String _reversibleToken(
    PrivacyFinding finding,
    Map<String, int> counters,
    Map<String, String> tokenByValue,
    Map<String, ReplacementMapping> mappings,
  ) {
    // Python Desktop uses Unicode casefold(). Dart core has no exact equivalent.
    // The canonical fixture suite will freeze any additional normalization needed.
    final key = '${finding.entityType}\u0000${finding.text.toLowerCase()}';
    var token = tokenByValue[key];
    if (token == null) {
      final next = (counters[finding.entityType] ?? 0) + 1;
      counters[finding.entityType] = next;
      token = '[[PG_${finding.entityType}_${next.toString().padLeft(3, '0')}]]';
      tokenByValue[key] = token;
      mappings[token] = ReplacementMapping(
        token: token,
        entityType: finding.entityType,
        originalText: finding.text,
      );
    }
    return token;
  }

  static String _maskValue(String value) {
    const visible = 4;
    final alphanumericPositions = <int>[];
    for (var index = 0; index < value.length; index += 1) {
      if (_isAlphaNumeric(value[index])) {
        alphanumericPositions.add(index);
      }
    }
    final keep = alphanumericPositions.length <= visible
        ? alphanumericPositions.toSet()
        : alphanumericPositions
            .sublist(alphanumericPositions.length - visible)
            .toSet();
    final output = StringBuffer();
    for (var index = 0; index < value.length; index += 1) {
      final character = value[index];
      output.write(
        keep.contains(index) || !_isAlphaNumeric(character) ? character : '*',
      );
    }
    return output.toString();
  }

  static bool _isAlphaNumeric(String character) {
    return RegExp(r'^[\p{L}\p{N}]$', unicode: true).hasMatch(character);
  }

  static void _validateDocumentFindings(
    AnalysisDocument document,
    List<PrivacyFinding> findings,
  ) {
    final pagesByNumber = <int, PageContent>{
      for (final page in document.pages) page.pageNumber: page,
    };
    final previousEndByPage = <int, int>{};

    for (final finding in findings) {
      final page = pagesByNumber[finding.pageNumber];
      if (page == null) {
        throw StateError(
          'Finding references missing page ${finding.pageNumber}: ${finding.findingId}',
        );
      }
      if (
          finding.start < 0 ||
          finding.end > page.text.length ||
          finding.start >= finding.end) {
        throw StateError('Invalid finding span: ${finding.findingId}');
      }
      final previousEnd = previousEndByPage[finding.pageNumber] ?? -1;
      if (finding.start < previousEnd) {
        throw StateError('Overlapping findings are not accepted.');
      }
      if (page.text.substring(finding.start, finding.end) != finding.text) {
        throw StateError('Finding text no longer matches the source span.');
      }
      previousEndByPage[finding.pageNumber] = finding.end;
    }
  }
}
