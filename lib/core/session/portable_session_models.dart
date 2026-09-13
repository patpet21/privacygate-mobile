import '../domain/replacement_mapping.dart';

enum MappingState {
  none('none'),
  protectedOnly('protected-only'),
  availableEncrypted('available-encrypted');

  const MappingState(this.wireValue);
  final String wireValue;
}

enum SyncState {
  local('local'),
  pending('pending'),
  synced('synced'),
  conflict('conflict'),
  deleted('deleted');

  const SyncState(this.wireValue);
  final String wireValue;
}

class SessionManifest {
  const SessionManifest({
    required this.sessionId,
    required this.sourceDeviceId,
    required this.createdAt,
    required this.updatedAt,
    required this.turn,
    required this.profileKey,
    required this.language,
    required this.replacementMode,
    required this.mappingState,
    required this.artifactRefs,
    required this.revision,
    required this.syncState,
    this.scopeKey,
  });

  static const schemaVersion = 'pg-session-v1';
  static const placeholderSchema = 'pg-placeholder-v1';
  static const mappingSchema = 'pg-mapping-v1';

  final String sessionId;
  final String sourceDeviceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int turn;
  final String profileKey;
  final String? scopeKey;
  final String language;
  final String replacementMode;
  final MappingState mappingState;
  final List<String> artifactRefs;
  final int revision;
  final SyncState syncState;

  Map<String, Object?> toJson() => {
        'schema_version': schemaVersion,
        'session_id': sessionId,
        'source_device_id': sourceDeviceId,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'turn': turn,
        'profile_key': profileKey,
        if (scopeKey != null) 'scope_key': scopeKey,
        'language': language,
        'replacement_mode': replacementMode,
        'placeholder_schema': placeholderSchema,
        'mapping_schema': mappingSchema,
        'mapping_state': mappingState.wireValue,
        'artifact_refs': artifactRefs,
        'revision': revision,
        'sync_state': syncState.wireValue,
      };
}

class ProtectedArtifact {
  const ProtectedArtifact({
    required this.artifactId,
    required this.sourceKind,
    required this.contentType,
    required this.safeTitle,
    required this.profileKey,
    required this.replacementMode,
    required this.entityTypes,
    required this.findingsCount,
    required this.contentHash,
    required this.createdAt,
    required this.updatedAt,
    required this.revision,
    this.sessionId,
    this.protectedText,
    this.deleted = false,
  });

  static const schemaVersion = 'pg-artifact-v1';

  final String artifactId;
  final String? sessionId;
  final String sourceKind;
  final String contentType;
  final String safeTitle;
  final String profileKey;
  final String replacementMode;
  final String? protectedText;
  final List<String> entityTypes;
  final int findingsCount;
  final String contentHash;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int revision;
  final bool deleted;

  Map<String, Object?> toJson() => {
        'schema_version': schemaVersion,
        'artifact_id': artifactId,
        if (sessionId != null) 'session_id': sessionId,
        'source_kind': sourceKind,
        'content_type': contentType,
        'safe_title': safeTitle,
        'profile_key': profileKey,
        'replacement_mode': replacementMode,
        if (protectedText != null) 'protected_text': protectedText,
        'entity_types': entityTypes,
        'findings_count': findingsCount,
        'content_hash': contentHash,
        'created_at': createdAt.toUtc().toIso8601String(),
        'updated_at': updatedAt.toUtc().toIso8601String(),
        'revision': revision,
        'deleted': deleted,
      };
}

/// Sensitive logical restore object. Do not persist this JSON in ordinary app
/// storage; retained/transmitted forms must be encrypted by the Mobile Vault or
/// paired-device transport layer.
class RestoreBundle {
  const RestoreBundle({
    required this.sessionId,
    required this.turn,
    required this.mappings,
  });

  static const schemaVersion = 'pg-restore-v1';

  final String sessionId;
  final int turn;
  final List<ReplacementMapping> mappings;

  Map<String, Object?> toJson() => {
        'schema_version': schemaVersion,
        'session_id': sessionId,
        'turn': turn,
        'mappings': [
          for (final mapping in mappings)
            {
              'token': mapping.token,
              'entity_type': mapping.entityType,
              'original_text': mapping.originalText,
            },
        ],
      };
}
