import '../domain/replacement_mapping.dart';
import '../profiles/document_languages.dart';
import '../profiles/privacy_profiles.dart';
import '../settings/privacy_gate_settings.dart';
import 'portable_session_models.dart';

class PortableSessionCodec {
  const PortableSessionCodec._();

  static final RegExp _sessionId = RegExp(r'^[0-9a-f]{32}$');
  static final RegExp _baseOrNamespacedToken = RegExp(
    r'^\[\[PG_[A-Z0-9_]+_\d{3}\]\]$',
  );

  static SessionManifest decodeSessionManifest(Map<String, Object?> json) {
    _requireSchema(json, SessionManifest.schemaVersion);
    _requireExact(json, 'placeholder_schema', SessionManifest.placeholderSchema);
    _requireExact(json, 'mapping_schema', SessionManifest.mappingSchema);

    final sessionId = _string(json, 'session_id');
    _validateSessionId(sessionId);
    final profileKey = _string(json, 'profile_key');
    getProfile(profileKey);
    final scopeKey = json['scope_key'] as String?;
    if (scopeKey != null) getScope(scopeKey);
    final language = _string(json, 'language');
    getDocumentLanguage(language);
    final replacementMode = _string(json, 'replacement_mode');
    if (!ReplacementMode.values.any((item) => item.wireValue == replacementMode)) {
      throw FormatException('Unsupported replacement_mode: $replacementMode');
    }

    final turn = _integer(json, 'turn');
    final revision = _integer(json, 'revision');
    if (turn < 0) throw const FormatException('turn must be >= 0');
    if (revision < 0) throw const FormatException('revision must be >= 0');

    return SessionManifest(
      sessionId: sessionId,
      sourceDeviceId: _string(json, 'source_device_id'),
      createdAt: _dateTime(json, 'created_at'),
      updatedAt: _dateTime(json, 'updated_at'),
      turn: turn,
      profileKey: profileKey,
      scopeKey: scopeKey,
      language: language,
      replacementMode: replacementMode,
      mappingState: _mappingState(_string(json, 'mapping_state')),
      artifactRefs: _stringList(json, 'artifact_refs'),
      revision: revision,
      syncState: _syncState(_string(json, 'sync_state')),
    );
  }

  static ProtectedArtifact decodeProtectedArtifact(Map<String, Object?> json) {
    _requireSchema(json, ProtectedArtifact.schemaVersion);
    final sessionId = json['session_id'] as String?;
    if (sessionId != null) _validateSessionId(sessionId);
    final profileKey = _string(json, 'profile_key');
    getProfile(profileKey);
    final replacementMode = _string(json, 'replacement_mode');
    if (!ReplacementMode.values.any((item) => item.wireValue == replacementMode)) {
      throw FormatException('Unsupported replacement_mode: $replacementMode');
    }
    final findingsCount = _integer(json, 'findings_count');
    final revision = _integer(json, 'revision');
    if (findingsCount < 0) throw const FormatException('findings_count must be >= 0');
    if (revision < 0) throw const FormatException('revision must be >= 0');

    return ProtectedArtifact(
      artifactId: _string(json, 'artifact_id'),
      sessionId: sessionId,
      sourceKind: _string(json, 'source_kind'),
      contentType: _string(json, 'content_type'),
      safeTitle: _string(json, 'safe_title'),
      profileKey: profileKey,
      replacementMode: replacementMode,
      protectedText: json['protected_text'] as String?,
      entityTypes: _stringList(json, 'entity_types'),
      findingsCount: findingsCount,
      contentHash: _string(json, 'content_hash'),
      createdAt: _dateTime(json, 'created_at'),
      updatedAt: _dateTime(json, 'updated_at'),
      revision: revision,
      deleted: (json['deleted'] as bool?) ?? false,
    );
  }

  static RestoreBundle decodeRestoreBundle(Map<String, Object?> json) {
    _requireSchema(json, RestoreBundle.schemaVersion);
    final sessionId = _string(json, 'session_id');
    _validateSessionId(sessionId);
    final turn = _integer(json, 'turn');
    if (turn < 0) throw const FormatException('turn must be >= 0');

    final rawMappings = json['mappings'];
    if (rawMappings is! List) {
      throw const FormatException('mappings must be a list');
    }
    final mappings = <ReplacementMapping>[];
    final seenTokens = <String>{};
    for (final raw in rawMappings) {
      if (raw is! Map) throw const FormatException('mapping entry must be an object');
      final item = Map<String, Object?>.from(raw);
      final token = _string(item, 'token');
      if (!_baseOrNamespacedToken.hasMatch(token)) {
        throw FormatException('Invalid PrivacyGate token: $token');
      }
      if (!seenTokens.add(token)) {
        throw FormatException('Duplicate mapping token: $token');
      }
      mappings.add(
        ReplacementMapping(
          token: token,
          entityType: _string(item, 'entity_type'),
          originalText: _string(item, 'original_text'),
        ),
      );
    }

    return RestoreBundle(
      sessionId: sessionId,
      turn: turn,
      mappings: List.unmodifiable(mappings),
    );
  }

  static void _requireSchema(Map<String, Object?> json, String expected) {
    _requireExact(json, 'schema_version', expected);
  }

  static void _requireExact(
    Map<String, Object?> json,
    String key,
    String expected,
  ) {
    final actual = json[key];
    if (actual != expected) {
      throw FormatException('$key must be $expected, got $actual');
    }
  }

  static String _string(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! String || value.isEmpty) {
      throw FormatException('$key must be a non-empty string');
    }
    return value;
  }

  static int _integer(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! num || value.toInt() != value) {
      throw FormatException('$key must be an integer');
    }
    return value.toInt();
  }

  static DateTime _dateTime(Map<String, Object?> json, String key) {
    final parsed = DateTime.tryParse(_string(json, key));
    if (parsed == null) throw FormatException('$key must be an ISO-8601 timestamp');
    return parsed.toUtc();
  }

  static List<String> _stringList(Map<String, Object?> json, String key) {
    final value = json[key];
    if (value is! List || value.any((item) => item is! String)) {
      throw FormatException('$key must be a string list');
    }
    return List.unmodifiable(value.cast<String>());
  }

  static MappingState _mappingState(String value) =>
      MappingState.values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => throw FormatException('Unsupported mapping_state: $value'),
      );

  static SyncState _syncState(String value) => SyncState.values.firstWhere(
        (item) => item.wireValue == value,
        orElse: () => throw FormatException('Unsupported sync_state: $value'),
      );

  static void _validateSessionId(String value) {
    if (!_sessionId.hasMatch(value)) {
      throw FormatException('session_id must be 32 lowercase hexadecimal characters');
    }
  }
}
