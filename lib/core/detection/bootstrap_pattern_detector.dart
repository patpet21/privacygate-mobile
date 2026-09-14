import '../domain/privacy_finding.dart';
import 'detection_engine.dart';

/// Temporary detector used only to validate the mobile interaction shell.
/// It is not the production PrivacyGate detector.
class BootstrapPatternDetector implements DetectionEngine {
  const BootstrapPatternDetector();

  static final RegExp _email = RegExp(
    r'\b[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}\b',
    caseSensitive: false,
  );

  static final RegExp _phone = RegExp(
    r'(?:\+?1[\s.-]?)?(?:\(?\d{3}\)?[\s.-]?)\d{3}[\s.-]?\d{4}',
  );

  @override
  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async {
    final text = request.text;
    final allowed = request.entities.toSet();
    final findings = <PrivacyFinding>[];
    var emailIndex = 0;
    var phoneIndex = 0;

    if (allowed.contains('EMAIL_ADDRESS')) {
      for (final match in _email.allMatches(text)) {
        emailIndex += 1;
        findings.add(
          PrivacyFinding(
            findingId: 'EMAIL_ADDRESS_${emailIndex.toString().padLeft(3, '0')}',
            entityType: 'EMAIL_ADDRESS',
            text: match.group(0)!,
            start: match.start,
            end: match.end,
            score: 1,
            context: text,
          ),
        );
      }
    }

    if (allowed.contains('PHONE_NUMBER')) {
      for (final match in _phone.allMatches(text)) {
        phoneIndex += 1;
        findings.add(
          PrivacyFinding(
            findingId: 'PHONE_NUMBER_${phoneIndex.toString().padLeft(3, '0')}',
            entityType: 'PHONE_NUMBER',
            text: match.group(0)!,
            start: match.start,
            end: match.end,
            score: 1,
            context: text,
          ),
        );
      }
    }

    findings.sort((a, b) => a.start.compareTo(b.start));
    return findings;
  }
}
