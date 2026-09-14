import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/replacement_mapping.dart';
import 'package:privacygate/core/session/portable_session_codec.dart';
import 'package:privacygate/core/session/portable_session_models.dart';

void main() {
  test('contract: session manifest round trips through strict decoder', () {
    final source = SessionManifest(
      sessionId: List.filled(32, 'a').join(),
      sourceDeviceId: 'device-test',
      createdAt: DateTime.utc(2026, 9, 13),
      updatedAt: DateTime.utc(2026, 9, 13, 1),
      turn: 3,
      profileKey: 'property_management',
      scopeKey: 'maximum',
      language: 'en',
      replacementMode: 'reversible',
      mappingState: MappingState.availableEncrypted,
      artifactRefs: const ['artifact-1'],
      revision: 2,
      syncState: SyncState.pending,
    );

    final decoded = PortableSessionCodec.decodeSessionManifest(source.toJson());
    expect(decoded.sessionId, source.sessionId);
    expect(decoded.turn, 3);
    expect(decoded.profileKey, 'property_management');
    expect(decoded.mappingState, MappingState.availableEncrypted);
  });

  test('contract: restore bundle rejects wrong schema and duplicate tokens', () {
    final sessionId = List.filled(32, 'b').join();
    final bundle = RestoreBundle(
      sessionId: sessionId,
      turn: 1,
      mappings: const [
        ReplacementMapping(
          token: '[[PG_PERSON_001]]',
          entityType: 'PERSON',
          originalText: 'Example Person',
        ),
      ],
    );

    final decoded = PortableSessionCodec.decodeRestoreBundle(bundle.toJson());
    expect(decoded.mappings.single.token, '[[PG_PERSON_001]]');

    final wrongSchema = Map<String, Object?>.from(bundle.toJson())
      ..['schema_version'] = 'pg-restore-v2';
    expect(
      () => PortableSessionCodec.decodeRestoreBundle(wrongSchema),
      throwsFormatException,
    );

    final mapping = Map<String, Object?>.from(
      (bundle.toJson()['mappings']! as List<Object?>).single as Map,
    );
    final duplicate = Map<String, Object?>.from(bundle.toJson())
      ..['mappings'] = [mapping, Map<String, Object?>.from(mapping)];
    expect(
      () => PortableSessionCodec.decodeRestoreBundle(duplicate),
      throwsFormatException,
    );
  });
}
