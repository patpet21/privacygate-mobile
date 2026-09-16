import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/page_content.dart';
import 'package:privacygate/core/domain/privacy_finding.dart';
import 'package:privacygate/core/domain/protection_result.dart';
import 'package:privacygate/core/domain/replacement_mapping.dart';
import 'package:privacygate/core/library/local_library_repository.dart';
import 'package:privacygate/core/library/protected_library_service.dart';
import 'package:privacygate/core/vault/encrypted_vault_repository.dart';
import 'package:privacygate/core/vault/vault_cryptor.dart';

void main() {
  late Directory root;
  late Directory libraryDirectory;
  late Directory vaultDirectory;
  late _XorVaultCryptor cryptor;
  late ProtectedLibraryService service;

  setUp(() async {
    root = await Directory.systemTemp.createTemp('privacygate_saved_protection_test_');
    libraryDirectory = Directory('${root.path}${Platform.pathSeparator}Library');
    vaultDirectory = Directory('${root.path}${Platform.pathSeparator}Vault');
    cryptor = _XorVaultCryptor(vaultDirectory);
    service = ProtectedLibraryService(
      library: LocalLibraryRepository(directory: libraryDirectory),
      vault: EncryptedVaultRepository(directory: vaultDirectory, cryptor: cryptor),
    );
  });

  tearDown(() async {
    service.dispose();
    if (await root.exists()) await root.delete(recursive: true);
  });

  test('reversible save separates protected Library data from encrypted mappings', () async {
    final document = await service.saveVerifiedProtection(
      profileKey: 'general_business',
      result: _reversibleResult(),
      title: 'Safe copy',
    );

    expect(document.hasMapping, isTrue);
    expect(await service.listDocuments(), hasLength(1));

    final libraryText = await File(
      '${libraryDirectory.path}${Platform.pathSeparator}library.json',
    ).readAsString();
    expect(libraryText, contains('[[PG_PERSON_001]]'));
    expect(libraryText, isNot(contains('Jane Doe')));

    final vaultFile = File(
      '${vaultDirectory.path}${Platform.pathSeparator}${document.documentId}.pgvault',
    );
    expect(await vaultFile.exists(), isTrue);
    expect(await vaultFile.readAsString(), isNot(contains('Jane Doe')));

    final loaded = await service.loadProtection(document.documentId);
    expect(loaded.document.protectedText, 'Hello [[PG_PERSON_001]]');
    expect(loaded.mappings.single.originalText, 'Jane Doe');
  });

  test('non-reversible save creates no Vault mapping record', () async {
    final document = await service.saveVerifiedProtection(
      profileKey: 'general_business',
      result: const ProtectionResult(
        protectedPages: [PageContent(pageNumber: 1, text: 'Hello [REDACTED]')],
        replacementMode: 'redact',
      ),
    );

    expect(document.hasMapping, isFalse);
    final vaultFile = File(
      '${vaultDirectory.path}${Platform.pathSeparator}${document.documentId}.pgvault',
    );
    expect(await vaultFile.exists(), isFalse);
    expect((await service.loadProtection(document.documentId)).mappings, isEmpty);
  });

  test('saved protection reopens through new service instances', () async {
    final saved = await service.saveVerifiedProtection(
      profileKey: 'property_management',
      result: _reversibleResult(),
    );

    final reopened = ProtectedLibraryService(
      library: LocalLibraryRepository(directory: libraryDirectory),
      vault: EncryptedVaultRepository(directory: vaultDirectory, cryptor: cryptor),
    );
    addTearDown(reopened.dispose);

    final loaded = await reopened.loadProtection(saved.documentId);
    expect(loaded.document.profileKey, 'property_management');
    expect(loaded.mappings.single.token, '[[PG_PERSON_001]]');
    expect(await reopened.storageBytes(), greaterThan(0));
  });
}

ProtectionResult _reversibleResult() => const ProtectionResult(
      protectedPages: [
        PageContent(pageNumber: 1, text: 'Hello [[PG_PERSON_001]]'),
      ],
      appliedFindings: [
        PrivacyFinding(
          findingId: 'p1-6-14-0',
          entityType: 'PERSON',
          text: 'Jane Doe',
          start: 6,
          end: 14,
          score: 1,
          pageNumber: 1,
          context: 'Hello Jane Doe',
        ),
      ],
      mappings: [
        ReplacementMapping(
          token: '[[PG_PERSON_001]]',
          entityType: 'PERSON',
          originalText: 'Jane Doe',
        ),
      ],
      replacementMode: 'reversible',
    );

class _XorVaultCryptor implements VaultCryptor {
  _XorVaultCryptor(this.directory);

  final Directory directory;

  @override
  Future<Directory> vaultDirectory() async => directory;

  @override
  Future<VaultCiphertext> encrypt(
    List<int> clearText, {
    required List<int> aad,
  }) async => VaultCiphertext(
        nonce: List<int>.filled(12, 7),
        cipherText: clearText.map((value) => value ^ 0xa5).toList(growable: false),
      );

  @override
  Future<List<int>> decrypt(
    VaultCiphertext ciphertext, {
    required List<int> aad,
  }) async =>
      ciphertext.cipherText.map((value) => value ^ 0xa5).toList(growable: false);

  @override
  Future<void> deleteKey() async {}
}
