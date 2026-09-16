class DesktopProtectedCopyGrant {
  const DesktopProtectedCopyGrant({
    required this.grantId,
    required this.documentId,
    required this.title,
    required this.profileKey,
    required this.findingsCount,
    required this.entityTypes,
    required this.labels,
    required this.updatedAt,
    required this.favorite,
    required this.sourceKind,
  });

  final String grantId;
  final String documentId;
  final String title;
  final String profileKey;
  final int findingsCount;
  final List<String> entityTypes;
  final List<String> labels;
  final DateTime updatedAt;
  final bool favorite;
  final String sourceKind;

  bool get hasMapping => false;
  String get localDocumentId => 'desktop_$documentId';

  factory DesktopProtectedCopyGrant.fromJson(Map<String, Object?> json) {
    if (json['mode'] != 'protected_copy' || json['has_mapping'] != false) {
      throw const FormatException(
        'Only protected-copy grants without restore mappings are accepted.',
      );
    }
    return DesktopProtectedCopyGrant(
      grantId: _requiredString(json, 'grant_id'),
      documentId: _requiredString(json, 'document_id'),
      title: _requiredString(json, 'title'),
      profileKey: _requiredString(json, 'profile_key'),
      findingsCount: _requiredInt(json, 'findings_count'),
      entityTypes: _stringList(json['entity_types']),
      labels: _stringList(json['labels']),
      updatedAt: DateTime.parse(_requiredString(json, 'updated_at')).toUtc(),
      favorite: json['favorite'] == true,
      sourceKind: json['source_kind'] is String
          ? json['source_kind']! as String
          : 'protected',
    );
  }
}

class DesktopProtectedCopyDocument extends DesktopProtectedCopyGrant {
  const DesktopProtectedCopyDocument({
    required super.grantId,
    required super.documentId,
    required super.title,
    required super.profileKey,
    required super.findingsCount,
    required super.entityTypes,
    required super.labels,
    required super.updatedAt,
    required super.favorite,
    required super.sourceKind,
    required this.protectedText,
  });

  final String protectedText;

  factory DesktopProtectedCopyDocument.fromJson(Map<String, Object?> json) {
    final grant = DesktopProtectedCopyGrant.fromJson(json);
    final protectedText = json['protected_text'];
    if (protectedText is! String || protectedText.isEmpty) {
      throw const FormatException('Protected copy is missing protected_text.');
    }
    return DesktopProtectedCopyDocument(
      grantId: grant.grantId,
      documentId: grant.documentId,
      title: grant.title,
      profileKey: grant.profileKey,
      findingsCount: grant.findingsCount,
      entityTypes: grant.entityTypes,
      labels: grant.labels,
      updatedAt: grant.updatedAt,
      favorite: grant.favorite,
      sourceKind: grant.sourceKind,
      protectedText: protectedText,
    );
  }
}

String _requiredString(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, Object?> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }
  return value;
}

List<String> _stringList(Object? value) {
  if (value == null) return const <String>[];
  if (value is! List || value.any((item) => item is! String)) {
    throw const FormatException('Expected a string list.');
  }
  return List<String>.unmodifiable(value.cast<String>());
}
