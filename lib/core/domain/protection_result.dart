import 'replacement_mapping.dart';

class ProtectionResult {
  const ProtectionResult({
    required this.protectedText,
    required this.mappings,
    required this.replacementMode,
  });

  final String protectedText;
  final List<ReplacementMapping> mappings;
  final String replacementMode;
}
