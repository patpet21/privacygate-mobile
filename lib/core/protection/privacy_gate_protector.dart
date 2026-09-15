import '../domain/page_content.dart';
import '../domain/privacy_finding.dart';
import '../domain/protected_span.dart';
import '../domain/protection_result.dart';
import '../domain/replacement_mapping.dart';
import '../settings/privacy_gate_settings.dart';

class PrivacyGateProtector {
  const PrivacyGateProtector();

  ProtectionResult protect(
    String text,
    Iterable<PrivacyFinding> selected, {
    ReplacementMode replacementMode = ReplacementMode.reversible,
  }) {
    final findings = selected.toList()..sort((a, b) => a.start.compareTo(b.start));
    _validateSpans(text, findings);

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

    final output = StringBuffer();
    final protectedSpans = <ProtectedSpan>[];
    var sourceCursor = 0;
    var protectedCursor = 0;

    for (final finding in findings) {
      final untouched = text.substring(sourceCursor, finding.start);
      output.write(untouched);
      protectedCursor += untouched.length;

      final replacement = replacements[finding.findingId]!;
      final spanStart = protectedCursor;
      output.write(replacement);
      protectedCursor += replacement.length;
      protectedSpans.add(
        ProtectedSpan(
          pageNumber: finding.pageNumber,
          start: spanStart,
          end: protectedCursor,
          entityType: finding.entityType,
          findingId: finding.findingId,
          replacementText: replacement,
        ),
      );
      sourceCursor = finding.end;
    }
    output.write(text.substring(sourceCursor));

    final protectedText = output.toString();
    return ProtectionResult(
      protectedPages: [
        PageContent(pageNumber: 1, text: protectedText),
      ],
      appliedFindings: List.unmodifiable(findings),
      mappings: List.unmodifiable(mappings.values),
      protectedSpans: List.unmodifiable(protectedSpans),
      replacementMode: replacementMode.wireValue,
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
        : alphanumericPositions.sublist(alphanumericPositions.length - visible).toSet();
    final output = StringBuffer();
    for (var index = 0; index < value.length; index += 1) {
      final character = value[index];
      output.write(keep.contains(index) || !_isAlphaNumeric(character) ? character : '*');
    }
    return output.toString();
  }

  static bool _isAlphaNumeric(String character) {
    return RegExp(r'^[\p{L}\p{N}]$', unicode: true).hasMatch(character);
  }

  static void _validateSpans(String text, List<PrivacyFinding> findings) {
    var previousEnd = -1;
    for (final finding in findings) {
      if (finding.start < 0 || finding.end > text.length || finding.start >= finding.end) {
        throw StateError('Invalid finding span: ${finding.findingId}');
      }
      if (finding.start < previousEnd) {
        throw StateError('Overlapping findings are not accepted.');
      }
      if (text.substring(finding.start, finding.end) != finding.text) {
        throw StateError('Finding text no longer matches the source span.');
      }
      previousEnd = finding.end;
    }
  }
}
