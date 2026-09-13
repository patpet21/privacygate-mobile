import '../domain/privacy_finding.dart';
import '../domain/protection_result.dart';
import '../domain/replacement_mapping.dart';

class PrivacyGateProtector {
  const PrivacyGateProtector();

  ProtectionResult protect(String text, Iterable<PrivacyFinding> selected) {
    final findings = selected.toList()..sort((a, b) => a.start.compareTo(b.start));
    _validateSpans(text, findings);

    final counters = <String, int>{};
    final tokenByValue = <String, String>{};
    final mappings = <String, ReplacementMapping>{};
    final replacements = <String, String>{};

    for (final finding in findings) {
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
      replacements[finding.findingId] = token;
    }

    var protectedText = text;
    for (final finding in findings.reversed) {
      protectedText = protectedText.replaceRange(
        finding.start,
        finding.end,
        replacements[finding.findingId]!,
      );
    }

    return ProtectionResult(
      protectedText: protectedText,
      mappings: mappings.values.toList(growable: false),
      replacementMode: 'reversible',
    );
  }

  String restore(String text, Iterable<ReplacementMapping> mappings) {
    var restored = text;
    for (final mapping in mappings) {
      restored = restored.replaceAll(mapping.token, mapping.originalText);
    }
    return restored;
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
