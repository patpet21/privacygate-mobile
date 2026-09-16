import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/library_document.dart';
import 'package:privacygate/core/library/local_library_repository.dart';

void main() {
  late Directory tempDirectory;
  late LocalLibraryRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('privacygate_library_test_');
    repository = LocalLibraryRepository(directory: tempDirectory);
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('library persists protected metadata and reopens it', () async {
    final document = _document('doc_001');
    await repository.save(document);

    final reopened = LocalLibraryRepository(directory: tempDirectory);
    final documents = await reopened.listDocuments();

    expect(documents, hasLength(1));
    expect(documents.single.documentId, 'doc_001');
    expect(documents.single.protectedText, 'Hello [[PG_PERSON_001]]');
    expect(documents.single.hasMapping, isTrue);
    expect(await reopened.storageBytes(), greaterThan(0));

    final stored = await repository.indexFile.readAsString();
    expect(stored, contains('[[PG_PERSON_001]]'));
    expect(stored, isNot(contains('Jane Doe')));
  });

  test('favorite metadata survives repository reopen', () async {
    await repository.save(_document('doc_002'));
    await repository.setFavorite('doc_002', true);

    final reopened = LocalLibraryRepository(directory: tempDirectory);
    final loaded = await reopened.get('doc_002');

    expect(loaded.favorite, isTrue);
    expect(loaded.mcpShared, isFalse);
  });
}

LibraryDocument _document(String id) {
  final now = DateTime.utc(2026, 9, 15, 23, 30);
  return LibraryDocument(
    documentId: id,
    title: 'Protected text',
    sourceKind: 'text',
    sourceName: 'Paste text',
    profileKey: 'general_business',
    protectedText: 'Hello [[PG_PERSON_001]]',
    findingsCount: 1,
    entityTypes: const ['PERSON'],
    labels: const [],
    replacementMode: 'reversible',
    createdAt: now,
    updatedAt: now,
    hasMapping: true,
  );
}
