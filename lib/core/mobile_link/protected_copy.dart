class ProtectedCopyGrant {
  const ProtectedCopyGrant({
    required this.grantId,
    required this.documentId,
    required this.title,
    required this.profileKey,
    required this.findingsCount,
    required this.entityTypes,
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
  final DateTime updatedAt;
  final bool favorite;
  final String sourceKind;

  bool get hasMapping => false;

  factory ProtectedCopyGrant.fromJson(Map<String, dynamic> json) {
    if (json['mode'] != 'protected_copy' || json['has_mapping'] != false) {
      throw const FormatException('Only protected-copy grants without mappings are accepted.');
    }
    return ProtectedCopyGrant(
      grantId: _requiredString(json, 'grant_id'),
      documentId: _requiredString(json, 'document_id'),
      title: _requiredString(json, 'title'),
      profileKey: _requiredString(json, 'profile_key'),
      findingsCount: _requiredInt(json, 'findings_count'),
      entityTypes: _stringList(json['entity_types']),
      updatedAt: DateTime.parse(_requiredString(json, 'updated_at')),
      favorite: json['favorite'] == true,
      sourceKind: (json['source_kind'] as String?) ?? 'protected',
    );
  }
}

class ProtectedCopyDocument extends ProtectedCopyGrant {
  const ProtectedCopyDocument({
    required super.grantId,
    required super.documentId,
    required super.title,
    required super.profileKey,
    required super.findingsCount,
    required super.entityTypes,
    required super.updatedAt,
    required super.favorite,
    required super.sourceKind,
    required this.protectedText,
  });

  final String protectedText;

  factory ProtectedCopyDocument.fromJson(Map<String, dynamic> json) {
    final grant = ProtectedCopyGrant.fromJson(json);
    final protectedText = json['protected_text'];
    if (protectedText is! String) {
      throw const FormatException('Protected copy is missing protected_text.');
    }
    return ProtectedCopyDocument(
      grantId: grant.grantId,
      documentId: grant.documentId,
      title: grant.title,
      profileKey: grant.profileKey,
      findingsCount: grant.findingsCount,
      entityTypes: grant.entityTypes,
      updatedAt: grant.updatedAt,
      favorite: grant.favorite,
      sourceKind: grant.sourceKind,
      protectedText: protectedText,
    );
  }

  Map<String, dynamic> toLocalJson() => {
        'grant_id': grantId,
        'mode': 'protected_copy',
        'document_id': documentId,
        'title': title,
        'profile_key': profileKey,
        'findings_count': findingsCount,
        'entity_types': entityTypes,
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'favorite': favorite,
        'source_kind': sourceKind,
        'has_mapping': false,
        'protected_text': protectedText,
      };
}

String _requiredString(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! String || value.isEmpty) {
    throw FormatException('$key must be a non-empty string.');
  }
  return value;
}

int _requiredInt(Map<String, dynamic> json, String key) {
  final value = json[key];
  if (value is! int) {
    throw FormatException('$key must be an integer.');
  }
  return value;
}

List<String> _stringList(dynamic value) {
  if (value == null) return const [];
  if (value is! List) throw const FormatException('Expected a string list.');
  return List<String>.unmodifiable(value.map((item) {
    if (item is! String) throw const FormatException('Expected a string list.');
    return item;
  }));
}
