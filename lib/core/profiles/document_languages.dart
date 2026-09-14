class DocumentLanguage {
  const DocumentLanguage({required this.code, required this.label});

  final String code;
  final String label;
}

const defaultDocumentLanguage = 'en';

const documentLanguages = <DocumentLanguage>[
  DocumentLanguage(code: 'en', label: 'English'),
  DocumentLanguage(code: 'it', label: 'Italiano'),
];

DocumentLanguage getDocumentLanguage(String code) =>
    documentLanguages.firstWhere((language) => language.code == code);
