import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/session/portable_session_models.dart';

void main() {
  test('session manifest serializes versioned mobile sync metadata', () {
    final manifest = SessionManifest(
      sessionId: List.filled(32, 'a').join(),
      sourceDeviceId: 'device-test',
      createdAt: DateTime.utc(2026, 9, 13),
      updatedAt: DateTime.utc(2026, 9, 13, 1),
      turn: 2,
      profileKey: 'property_management',
      scopeKey: 'maximum',
      language: 'en',
      replacementMode: 'reversible',
      mappingState: MappingState.availableEncrypted,
      artifactRefs: const ['artifact-1'],
      revision: 1,
      syncState: SyncState.pending,
    );

    final json = manifest.toJson();
    expect(json['schema_version'], 'pg-session-v1');
    expect(json['placeholder_schema'], 'pg-placeholder-v1');
    expect(json['mapping_schema'], 'pg-mapping-v1');
    expect(json['mapping_state'], 'available-encrypted');
  });
}
