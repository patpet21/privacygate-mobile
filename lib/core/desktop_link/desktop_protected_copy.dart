import '../domain/replacement_mapping.dart';

class DesktopProtectedCopyGrant {
  const DesktopProtectedCopyGrant({
    required this.grantId,
    required this.mode,
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
  final String mode;
  final String documentId;
  final String title;
  final String profileKey;
  final int findingsCount;
  final List<String> entityTypes;
  final List<String> labels;
  final DateTime updatedAt;
  final bool favorite;
  final String sourceKind;

  bool get isFullOfflineSession => mode == 'full_offline_session';
  bool get hasMapping => isFullOfflineSession;
  String get localDocumentId => 'desktop_$documentId';

  factory DesktopProtectedCopyGrant.fromJson(Map<String, Object?> json) {
    final mode = _requiredString(json, 'mode');
    if (mode != 'protected_copy' && mode != 'full_offline_session') {
      throw const FormatException('Desktop transfer mode is not supported.');
    }
    final hasMapping = json['has_mapping'];
    if (hasMapping is! bool ||
        (mode == 'protected_copy' && hasMapping) ||
        (mode == 'full_offline_session' && !hasMapping)) {
      throw const FormatException(
        'Desktop transfer mode and restore-mapping metadata do not match.',
      );
    }
    return DesktopProtectedCopyGrant(
      grantId: _requiredString(json, 'grant_id'),
      mode: mode,
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
    required super.mode,
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
    required this.restoreMappings,
  });

  final String protectedText;
  final List<ReplacementMapping> restoreMappings;

  factory DesktopProtectedCopyDocument.fromJson(Map<String, Object?> json) {
    final grant = DesktopProtectedCopyGrant.fromJson(json);
    final protectedText = json['protected_text'];
    if (protectedText is! String || protectedText.isEmpty) {
      throw const FormatException('Desktop transfer is missing protected_text.');
    }

    final mappings = _restoreMappings(json['restore_mappings']);
    if (grant.isFullOfflineSession && mappings.isEmpty) {
      throw const FormatException(
        'Full offline session is missing its Restore mapping.',
      );
    }
    if (!grant.isFullOfflineSession && mappings.isNotEmpty) {
      throw const FormatException(
        'Protected copy unexpectedly contains a Restore mapping.',
      );
    }
    if (grant.isFullOfflineSession &&
        json['mapping_storage'] != 'mobile_device_vault_aes_256_gcm') {
      throw const FormatException(
        'Full offline session does not declare the expected Mobile Vault storage.',
      );
    }

    return DesktopProtectedCopyDocument(
      grantId: grant.grantId,
      mode: grant.mode,
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
      restoreMappings: mappings,
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

List<ReplacementMapping> _restoreMappings(Object? value) {
  if (value == null) return const <ReplacementMapping>[];
  if (value is! List) {
    throw const FormatException('restore_mappings must be a list.');
  }
  final mappings = <ReplacementMapping>[];
  final tokens = <String>{};
  for (final raw in value) {
    if (raw is! Map) {
      throw const FormatException('Restore mapping entry is invalid.');
    }
    final token = raw['token'];
    final entityType = raw['entity_type'];
    final originalText = raw['original_text'];
    if (token is! String ||
        token.isEmpty ||
        entityType is! String ||
        entityType.isEmpty ||
        originalText is! String ||
        !tokens.add(token)) {
      throw const FormatException('Restore mapping fields are invalid.');
    }
    mappings.add(
      ReplacementMapping(
        token: token,
        entityType: entityType,
        originalText: originalText,
      ),
    );
  }
  mappings.sort((left, right) => left.token.compareTo(right.token));
  return List<ReplacementMapping>.unmodifiable(mappings);
}
