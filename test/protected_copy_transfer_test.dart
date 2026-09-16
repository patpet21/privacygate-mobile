import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/mobile_link/protected_copy.dart';

Map<String, dynamic> _grantJson({bool hasMapping = false}) => {
      'grant_id': 'grant_1234567890',
      'mode': 'protected_copy',
      'document_id': 'doc-123',
      'title': 'Protected contract',
      'profile_key': 'property_management',
      'findings_count': 3,
      'entity_types': ['PERSON', 'EMAIL_ADDRESS'],
      'updated_at': '2026-09-16T12:00:00Z',
      'favorite': false,
      'source_kind': 'protected',
      'has_mapping': hasMapping,
    };

void main() {
  test('protected-copy grant accepts only has_mapping false', () {
    final grant = ProtectedCopyGrant.fromJson(_grantJson());
    expect(grant.documentId, 'doc-123');
    expect(grant.hasMapping, isFalse);

    expect(
      () => ProtectedCopyGrant.fromJson(_grantJson(hasMapping: true)),
      throwsFormatException,
    );
  });

  test('local protected copy serialization cannot carry a mapping', () {
    final json = _grantJson()..['protected_text'] = 'Hello [[PERSON_001]]';
    final document = ProtectedCopyDocument.fromJson(json);
    final stored = document.toLocalJson();

    expect(stored['mode'], 'protected_copy');
    expect(stored['has_mapping'], isFalse);
    expect(stored['protected_text'], 'Hello [[PERSON_001]]');
    expect(stored.containsKey('mapping'), isFalse);
    expect(stored.containsKey('original'), isFalse);
    expect(stored.containsKey('restore_bundle'), isFalse);
  });
}
