import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/library_document.dart';

void main() {
  test('contract: library document defaults match Desktop domain model', () {
    final createdAt = DateTime.utc(2026, 9, 15, 20, 30);
    final updatedAt = DateTime.utc(2026, 9, 15, 20, 45);
    final document = LibraryDocument(
      documentId: 'doc-001',
      title: 'Protected lease',
      sourceKind: 'text',
      sourceName: 'pasted text',
      profileKey: 'property_management',
      protectedText: 'Tenant [[PG_PERSON_001]]',
      findingsCount: 1,
      entityTypes: const ['PERSON'],
      labels: const ['lease'],
      replacementMode: 'reversible',
      createdAt: createdAt,
      updatedAt: updatedAt,
      hasMapping: true,
    );

    expect(document.documentId, 'doc-001');
    expect(document.entityTypes, const ['PERSON']);
    expect(document.labels, const ['lease']);
    expect(document.favorite, isFalse);
    expect(document.mcpShared, isFalse);
    expect(document.deletedAt, isNull);
  });

  test('contract: library document carries trash and sharing metadata', () {
    final timestamp = DateTime.utc(2026, 9, 15, 21);
    final deletedAt = DateTime.utc(2026, 9, 15, 22);
    final document = LibraryDocument(
      documentId: 'doc-002',
      title: 'Protected record',
      sourceKind: 'file',
      sourceName: 'record.pdf',
      profileKey: 'general_business',
      protectedText: '[[PG_EMAIL_ADDRESS_001]]',
      findingsCount: 1,
      entityTypes: const ['EMAIL_ADDRESS'],
      labels: const [],
      replacementMode: 'reversible',
      createdAt: timestamp,
      updatedAt: timestamp,
      hasMapping: true,
      favorite: true,
      mcpShared: true,
      deletedAt: deletedAt,
    );

    expect(document.favorite, isTrue);
    expect(document.mcpShared, isTrue);
    expect(document.deletedAt, deletedAt);
  });
}
