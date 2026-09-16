import '../detection/detection_pack_catalog.dart';

class DocumentLanguage {
  const DocumentLanguage({required this.code, required this.label});

  final String code;
  final String label;
}

final String defaultDocumentLanguage = detectionPackCatalog.defaultLanguage;

final List<DocumentLanguage> documentLanguages =
    List<DocumentLanguage>.unmodifiable(
  detectionPackCatalog.languageValues.map(
    (value) => DocumentLanguage(
      code: value['code'] as String,
      label: value['label'] as String,
    ),
  ),
);

DocumentLanguage getDocumentLanguage(String code) =>
    documentLanguages.firstWhere((language) => language.code == code);
