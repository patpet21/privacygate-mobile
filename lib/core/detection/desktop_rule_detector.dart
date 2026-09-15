import 'dart:math' as math;

import '../domain/privacy_finding.dart';
import 'detection_engine.dart';

typedef _Validator = bool Function(String value);

/// Mobile-local deterministic detection layer derived from the pinned Desktop
/// PrivacyGate recognizers at commit 754f412596c7f32f04c3f50714dcd064704a3f13.
///
/// This intentionally ports deterministic rules first. Desktop semantic NER
/// (spaCy/Presidio PERSON/ORGANIZATION/LOCATION inference) is a separate layer
/// and is not emulated with guesses here.
class DesktopRuleDetector implements DetectionEngine {
  const DesktopRuleDetector();

  static final RegExp _protectedToken = RegExp(
    r'\[\[(?:PG_)?[A-Z0-9_]+(?:_\d{3})?\]\]|\[REDACTED\]',
  );

  static const Set<String> _italianAlwaysRequested = {
    'IT_FISCAL_CODE',
    'IT_VAT_NUMBER',
    'IBAN_CODE',
    'EMAIL_ADDRESS',
    'IT_PEC_ADDRESS',
    'PHONE_NUMBER',
    'STREET_ADDRESS',
    'IT_POSTAL_CODE',
    'IT_PROVINCE',
    'IT_ID_CARD',
    'IT_PASSPORT',
    'IT_DRIVER_LICENSE',
    'IT_VEHICLE_PLATE',
    'IT_CADASTRAL_MUNICIPAL_CODE',
    'IT_CADASTRAL_SECTION',
    'IT_CADASTRAL_SHEET',
    'IT_CADASTRAL_PARCEL',
    'IT_CADASTRAL_SUBALTERN',
    'IT_REA_NUMBER',
    'IT_BUSINESS_REGISTER_NUMBER',
    'PERSON',
    'ORGANIZATION',
  };

  static final List<_Rule> _commonRules = [
    _Rule(
      entityType: 'EMAIL_ADDRESS',
      pattern: RegExp(
        r"\b[A-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+\b",
        caseSensitive: false,
      ),
      score: 0.97,
    ),
    _Rule(
      entityType: 'IP_ADDRESS',
      pattern: RegExp(
        r'\b(?:25[0-5]|2[0-4]\d|1?\d?\d)(?:\.(?:25[0-5]|2[0-4]\d|1?\d?\d)){3}\b',
      ),
      score: 0.95,
    ),
    _Rule(
      entityType: 'CREDIT_CARD',
      pattern: RegExp(r'\b(?:\d[ -]?){12,18}\d\b'),
      score: 0.93,
      validator: _isValidCardNumber,
    ),
  ];

  static final List<_Rule> _englishRules = [
    _Rule(
      entityType: 'PHONE_NUMBER',
      pattern: RegExp(
        r'(?:(?:\+?1)[\s.-]?)?(?:\(?\d{3}\)?[\s.-]?)\d{3}[\s.-]?\d{4}',
      ),
      score: 0.90,
    ),
    _Rule(
      entityType: 'US_ITIN',
      pattern: RegExp(r'\b9\d{2}-\d{2}-\d{4}\b'),
      score: 0.995,
    ),
    _Rule(
      entityType: 'US_SSN',
      pattern: RegExp(r'\b\d{3}-\d{2}-\d{4}\b'),
      score: 0.99,
    ),
    _Rule(
      entityType: 'US_ROUTING_NUMBER',
      pattern: RegExp(
        r'\b(?:routing(?:\s+(?:number|no\.?))?|aba(?:\s+routing)?)\s*(?:[:#=.-])?\s*(\d{9})\b',
        caseSensitive: false,
      ),
      score: 0.995,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'US_BANK_NUMBER',
      pattern: RegExp(
        r'\b(?:(?:dedicated|primary|secondary)\s+)?(?:(?:bank|checking|savings|business|payment|operating|escrow|trust|deposit|rent)\s+)?account\s+(?:number|no\.?)\s*(?::|#|=)?\s*(\d{6,17})\b',
        caseSensitive: false,
        multiLine: true,
      ),
      score: 0.995,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'US_BANK_NUMBER',
      pattern: RegExp(
        r'\b(?:checking|savings|escrow|operating|rent)\s+(?:acct\.?|a/c)\s*(?:number|no\.?)?\s*(?::|#|=)?\s*(\d{6,17})\b',
        caseSensitive: false,
      ),
      score: 0.995,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'US_BANK_NUMBER',
      pattern: RegExp(
        r'\bBANK\s+ACCOUNT\s*[\r\n]+\s*(\d{6,17})\b',
        caseSensitive: false,
      ),
      score: 0.995,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'SWIFT_BIC',
      pattern: RegExp(
        r'\b(?:swift\s*/?\s*bic|swift|bic)\b\s*(?:(?:number|no\.?)\s*)?(?::|#)?\s*([A-Z]{6}[A-Z0-9]{2}(?:[A-Z0-9]{3})?)\b',
        caseSensitive: false,
      ),
      score: 0.995,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'CARD_LAST_FOUR',
      pattern: RegExp(r'\bending\s+in\s+(\d{4})\b', caseSensitive: false),
      score: 0.995,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'DATE_OF_BIRTH',
      pattern: RegExp(
        r'\b(?:date\s+of\s+birth|birth\s*date|dob)\b\s*(?:(?:number|no\.?)\s*)?(?::|#)?\s*((?:\d{1,2}[/-]){2}\d{2,4}|[A-Z][a-z]+\s+\d{1,2},?\s+\d{4})\b',
        caseSensitive: false,
      ),
      score: 0.99,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'PROPERTY_ACCESS_CODE',
      pattern: RegExp(
        r'\b(?:(?:building|property|door|gate|entry)\s+access|access)\s+(?:credential|code|pin)\s*[:#=-]?\s*((?=[A-Z0-9#*.-]*\d)[A-Z0-9#*.-]{4,32})(?=$|[\s,;.)\]}])',
        caseSensitive: false,
      ),
      score: 0.998,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'INVOICE_NUMBER',
      pattern: RegExp(
        r'\binvoice\s*(?:number|no\.?|id|#)?\s*(?::|#)?\s*((?:INV-)?[A-Z0-9][A-Z0-9-]{3,30})\b',
        caseSensitive: false,
      ),
      score: 0.98,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'PURCHASE_ORDER_ID',
      pattern: RegExp(
        r'\b(?:purchase\s+order|p\.?o\.?)\s*(?:number|no\.?|id)?\s*(?::|#)?\s*([A-Z0-9][A-Z0-9-]{3,30})\b',
        caseSensitive: false,
      ),
      score: 0.98,
      valueGroup: 1,
    ),
    _contextIdRule('CONTRACT_ID', 'contract', 'number|no\\.?|id|reference'),
    _contextIdRule('CUSTOMER_ID', '(?:customer|client)', 'number|no\\.?|id|identifier'),
    _contextIdRule('EMPLOYEE_ID', 'employee', 'number|no\\.?|id|identifier'),
    _contextIdRule('CASE_REFERENCE', 'case', 'number|no\\.?|id|reference'),
    _Rule(
      entityType: 'MONEY_AMOUNT',
      pattern: RegExp(
        r'(?:[-+]\s*)?(?:(?:[\$€£])\s*|(?:USD|EUR|GBP)\s*)?\d{1,3}(?:,\d{3})*\.\d{2}(?:\s*(?:USD|EUR|GBP))?',
        caseSensitive: false,
      ),
      score: 0.88,
    ),
    _Rule(
      entityType: 'POSTAL_CODE',
      pattern: RegExp(r'\b\d{5}(?:-\d{4})?\b'),
      score: 0.86,
    ),
    _Rule(
      entityType: 'STREET_ADDRESS',
      pattern: RegExp(
        r"\b\d{1,6}(?:-\d{1,6})?\s+(?:[A-Z0-9.'-]+\s+){1,8}(?:Street|St\.?|Avenue|Ave\.?|Road|Rd\.?|Boulevard|Blvd\.?|Lane|Ln\.?|Drive|Dr\.?|Court|Ct\.?|Parkway|Pkwy\.?|Highway|Hwy)(?=\s|,|$)(?:\s*,?\s*(?:Apt\.?|Apartment|Unit|Suite)\s+[A-Z0-9-]+)?",
        caseSensitive: false,
      ),
      score: 0.94,
    ),
  ];

  static final List<_Rule> _italianRules = [
    _Rule(
      entityType: 'EMAIL_ADDRESS',
      pattern: RegExp(
        r"\b[A-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+\b",
        caseSensitive: false,
      ),
      score: 0.97,
    ),
    _Rule(
      entityType: 'IT_PEC_ADDRESS',
      pattern: RegExp(
        r"\bpec(?:\s+address|\s+email|\s+mail)?\s*[:#-]?\s*([A-Z0-9.!#\$%&'*+/=?^_`{|}~-]+@[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?(?:\.[A-Z0-9](?:[A-Z0-9-]{0,61}[A-Z0-9])?)+)\b",
        caseSensitive: false,
      ),
      score: 0.995,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'PHONE_NUMBER',
      pattern: RegExp(
        r'\b(?:\+39|0039)[\s.-]?(?:3\d{2}|0\d{1,3})(?:[\s.-]?\d){6,8}\b',
      ),
      score: 0.97,
    ),
    _Rule(
      entityType: 'PHONE_NUMBER',
      pattern: RegExp(
        r'\b(?:telefono|tel\.?|cellulare|cell\.?|mobile|centralino)\s*(?:(?:n(?:umero)?\.?)\s*)?[:#-]?\s*((?:(?:\+39|0039)\s*)?(?:3\d{2}|0\d{1,3})(?:[\s./-]?\d){6,8})',
        caseSensitive: false,
      ),
      score: 0.985,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'IT_FISCAL_CODE',
      pattern: RegExp(
        r'\b[A-Z]{6}[0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{3}[A-Z]\b',
        caseSensitive: false,
      ),
      score: 0.99,
      validator: _isValidCodiceFiscale,
    ),
    _Rule(
      entityType: 'IT_FISCAL_CODE',
      pattern: RegExp(
        r"\b(?:codice\s+fiscale|c\.?\s*f\.?|cf)\b(?:\s+(?:(?:del|della|dello|di)\s+(?:cliente|intestatario|proprietario|locatore|conduttore|richiedente|beneficiario|soggetto|persona|dipendente|fornitore)|dell['’]\s*(?:cliente|intestatario|proprietario|locatore|conduttore|richiedente|beneficiario|soggetto|persona|dipendente|fornitore)))?\s*(?:n(?:umero)?\.?\s*)?(?:è|e|:|#|-)?\s*([A-Z]{6}[0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{3}[A-Z])\b",
        caseSensitive: false,
      ),
      score: 0.985,
      valueGroup: 1,
      validator: _isStructurallyPlausibleCodiceFiscale,
    ),
    _Rule(
      entityType: 'IT_VAT_NUMBER',
      pattern: RegExp(r'\b(?:IT\s*)?\d{11}\b', caseSensitive: false),
      score: 0.99,
      validator: _isValidPartitaIva,
    ),
    _Rule(
      entityType: 'IBAN_CODE',
      pattern: RegExp(
        r'\bIT(?:\s?[A-Z0-9]){25}\b',
        caseSensitive: false,
      ),
      score: 0.995,
      validator: _isValidItalianIban,
    ),
    _Rule(
      entityType: 'IT_POSTAL_CODE',
      pattern: RegExp(
        r'\b(?:cap|codice\s+postale)\s*[:#-]?\s*(\d{5})\b',
        caseSensitive: false,
      ),
      score: 0.97,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'DATE_OF_BIRTH',
      pattern: RegExp(
        r'\b(?:data\s+di\s+nascita|nato\s+il|nata\s+il)\s*[:#-]?\s*((?:\d{1,2}[/-]){2}\d{2,4})\b',
        caseSensitive: false,
      ),
      score: 0.99,
      valueGroup: 1,
    ),
    _Rule(
      entityType: 'STREET_ADDRESS',
      pattern: RegExp(
        r'\b(?:Via|Viale|Piazza|Corso|Largo|Vicolo)\s+[^\r\n,]{2,60}?\s+\d+[A-Z]?\b',
        caseSensitive: false,
      ),
      score: 0.93,
    ),
  ];

  @override
  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async {
    final language = request.scanLanguage.trim().toLowerCase();
    if (language != 'en' && language != 'it') {
      throw ArgumentError.value(
        request.scanLanguage,
        'scanLanguage',
        'Desktop-compatible mobile detector currently supports en and it.',
      );
    }

    final allowed = request.entities.toSet();
    if (language == 'it') {
      allowed.addAll(_italianAlwaysRequested);
    }

    final tokenSpans = _protectedToken
        .allMatches(request.text)
        .map((match) => (match.start, match.end))
        .toList(growable: false);

    final candidates = <PrivacyFinding>[];
    final rules = <_Rule>[
      ..._commonRules,
      if (language == 'en') ..._englishRules,
      if (language == 'it') ..._italianRules,
    ];

    for (final rule in rules) {
      if (!allowed.contains(rule.entityType) || rule.score < request.confidenceThreshold) {
        continue;
      }
      for (final match in rule.pattern.allMatches(request.text)) {
        final span = _spanForMatch(match, rule.valueGroup);
        if (span == null) continue;
        final start = span.$1;
        final end = span.$2;
        if (start < 0 || end <= start) continue;
        if (tokenSpans.any((span) => start < span.$2 && span.$1 < end)) continue;

        final value = request.text.substring(start, end);
        if (rule.validator != null && !rule.validator!(value)) continue;

        final contextStart = math.max(0, start - 48);
        final contextEnd = math.min(request.text.length, end + 48);
        candidates.add(
          PrivacyFinding(
            findingId: 'rule-${rule.entityType}-$start-$end',
            entityType: rule.entityType,
            text: value,
            start: start,
            end: end,
            score: rule.score,
            context: request.text.substring(contextStart, contextEnd),
          ),
        );
      }
    }

    final deduplicated = <String, PrivacyFinding>{};
    for (final item in candidates) {
      final key = '${item.entityType}:${item.start}:${item.end}';
      final current = deduplicated[key];
      if (current == null || item.score > current.score) {
        deduplicated[key] = item;
      }
    }

    final ordered = deduplicated.values.toList()
      ..sort((a, b) {
        final score = b.score.compareTo(a.score);
        if (score != 0) return score;
        final length = (b.end - b.start).compareTo(a.end - a.start);
        if (length != 0) return length;
        return a.start.compareTo(b.start);
      });

    final accepted = <PrivacyFinding>[];
    for (final candidate in ordered) {
      if (accepted.any(
        (current) => candidate.start < current.end && current.start < candidate.end,
      )) {
        continue;
      }
      accepted.add(candidate);
    }
    accepted.sort((a, b) {
      final start = a.start.compareTo(b.start);
      return start != 0 ? start : a.end.compareTo(b.end);
    });
    return List.unmodifiable(accepted);
  }

  static (int, int)? _spanForMatch(RegExpMatch match, int valueGroup) {
    if (valueGroup == 0) return (match.start, match.end);

    final value = match.group(valueGroup);
    final fullMatch = match.group(0);
    if (value == null || value.isEmpty || fullMatch == null) return null;

    // Current value-group rules capture the protected value at the end of the
    // larger context match. Dart Match exposes offsets only for the full match,
    // so resolve the captured value relative to that match without widening the
    // protected span to include labels such as "routing number" or "DOB".
    final relativeStart = fullMatch.lastIndexOf(value);
    if (relativeStart < 0) return null;
    final start = match.start + relativeStart;
    return (start, start + value.length);
  }

  static _Rule _contextIdRule(String entityType, String label, String qualifier) => _Rule(
        entityType: entityType,
        pattern: RegExp(
          '\\b$label\\s+(?:$qualifier)\\b\\s*(?::|#)?\\s*([A-Z0-9][A-Z0-9-]{3,30})\\b',
          caseSensitive: false,
        ),
        score: 0.98,
        valueGroup: 1,
      );

  static bool _isValidCardNumber(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 13 || digits.length > 19) return false;
    var sum = 0;
    var doubleNext = false;
    for (var index = digits.length - 1; index >= 0; index -= 1) {
      var digit = int.parse(digits[index]);
      if (doubleNext) {
        digit *= 2;
        if (digit > 9) digit -= 9;
      }
      sum += digit;
      doubleNext = !doubleNext;
    }
    return sum % 10 == 0;
  }

  static bool _isStructurallyPlausibleCodiceFiscale(String value) {
    final candidate = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    return RegExp(
      r'^[A-Z]{6}[0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{2}[A-Z][0-9LMNPQRSTUV]{3}[A-Z]$',
    ).hasMatch(candidate);
  }

  static bool _isValidCodiceFiscale(String value) {
    final candidate = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (!_isStructurallyPlausibleCodiceFiscale(candidate)) return false;

    const odd = <String, int>{
      '0': 1, '1': 0, '2': 5, '3': 7, '4': 9, '5': 13, '6': 15, '7': 17,
      '8': 19, '9': 21, 'A': 1, 'B': 0, 'C': 5, 'D': 7, 'E': 9, 'F': 13,
      'G': 15, 'H': 17, 'I': 19, 'J': 21, 'K': 2, 'L': 4, 'M': 18, 'N': 20,
      'O': 11, 'P': 3, 'Q': 6, 'R': 8, 'S': 12, 'T': 14, 'U': 16, 'V': 10,
      'W': 22, 'X': 25, 'Y': 24, 'Z': 23,
    };
    const even = <String, int>{
      '0': 0, '1': 1, '2': 2, '3': 3, '4': 4, '5': 5, '6': 6, '7': 7,
      '8': 8, '9': 9, 'A': 0, 'B': 1, 'C': 2, 'D': 3, 'E': 4, 'F': 5,
      'G': 6, 'H': 7, 'I': 8, 'J': 9, 'K': 10, 'L': 11, 'M': 12, 'N': 13,
      'O': 14, 'P': 15, 'Q': 16, 'R': 17, 'S': 18, 'T': 19, 'U': 20, 'V': 21,
      'W': 22, 'X': 23, 'Y': 24, 'Z': 25,
    };
    var total = 0;
    for (var index = 0; index < 15; index += 1) {
      final position = index + 1;
      total += (position.isOdd ? odd : even)[candidate[index]]!;
    }
    return candidate.codeUnitAt(15) == 'A'.codeUnitAt(0) + (total % 26);
  }

  static bool _isValidPartitaIva(String value) {
    final candidate = value.toUpperCase().replaceAll(RegExp(r'[^0-9]'), '');
    if (candidate.length != 11) return false;
    var total = 0;
    for (var index = 0; index < candidate.length; index += 1) {
      final digit = int.parse(candidate[index]);
      if (index.isEven) {
        total += digit;
      } else {
        final doubled = digit * 2;
        total += doubled > 9 ? doubled - 9 : doubled;
      }
    }
    return total % 10 == 0;
  }

  static bool _isValidItalianIban(String value) {
    final candidate = value.replaceAll(RegExp(r'\s+'), '').toUpperCase();
    if (!RegExp(r'^IT\d{2}[A-Z]\d{10}[A-Z0-9]{12}$').hasMatch(candidate)) {
      return false;
    }
    final rearranged = candidate.substring(4) + candidate.substring(0, 4);
    var remainder = 0;
    for (final codeUnit in rearranged.codeUnits) {
      final char = String.fromCharCode(codeUnit);
      final expanded = RegExp(r'[A-Z]').hasMatch(char)
          ? (codeUnit - 55).toString()
          : char;
      for (final digit in expanded.codeUnits) {
        remainder = (remainder * 10 + (digit - 48)) % 97;
      }
    }
    return remainder == 1;
  }
}

class _Rule {
  const _Rule({
    required this.entityType,
    required this.pattern,
    required this.score,
    this.valueGroup = 0,
    this.validator,
  });

  final String entityType;
  final RegExp pattern;
  final double score;
  final int valueGroup;
  final _Validator? validator;
}
