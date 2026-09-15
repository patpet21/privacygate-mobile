import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/domain/replacement_mapping.dart';
import 'package:privacygate/core/vault/encrypted_vault_repository.dart';
import 'package:privacygate/core/vault/vault_cryptor.dart';

void main() {
  late Directory tempDirectory;
  late _TestVaultCryptor cryptor;
  late EncryptedVaultRepository repository;

  setUp(() async {
    tempDirectory = await Directory.systemTemp.createTemp('privacygate_vault_test_');
    cryptor = _TestVaultCryptor(tempDirectory);
    repository = EncryptedVaultRepository(
      directory: tempDirectory,
      cryptor: cryptor,
    );
  });

  tearDown(() async {
    if (await tempDirectory.exists()) {
      await tempDirectory.delete(recursive: true);
    }
  });

  test('vault persists mappings without writing originals in plaintext', () async {
    const mappings = [
      ReplacementMapping(
        token: '[[PG_EMAIL_ADDRESS_001]]',
        entityType: 'EMAIL_ADDRESS',
        originalText: 'jane@example.com',
      ),
      ReplacementMapping(
        token: '[[PG_PERSON_001]]',
        entityType: 'PERSON',
        originalText: 'Jane Doe',
      ),
    ];

    await repository.saveMappings('doc_001', mappings);

    final file = File('${tempDirectory.path}${Platform.pathSeparator}doc_001.pgvault');
    final stored = await file.readAsString();
    expect(stored, isNot(contains('jane@example.com')));
    expect(stored, isNot(contains('Jane Doe')));
    expect(stored, isNot(contains('[[PG_EMAIL_ADDRESS_001]]')));

    final reopened = EncryptedVaultRepository(
      directory: tempDirectory,
      cryptor: cryptor,
    );
    final restored = await reopened.loadMappings('doc_001');

    expect(restored, hasLength(2));
    expect(restored[0].token, '[[PG_EMAIL_ADDRESS_001]]');
    expect(restored[0].originalText, 'jane@example.com');
    expect(restored[1].token, '[[PG_PERSON_001]]');
    expect(restored[1].originalText, 'Jane Doe');
  });

  test('vault rejects authenticated ciphertext tampering', () async {
    await repository.saveMappings(
      'doc_002',
      const [
        ReplacementMapping(
          token: '[[PG_PERSON_001]]',
          entityType: 'PERSON',
          originalText: 'Jane Doe',
        ),
      ],
    );

    final file = File('${tempDirectory.path}${Platform.pathSeparator}doc_002.pgvault');
    final envelope = jsonDecode(await file.readAsString()) as Map<String, dynamic>;
    final cipherText = base64Decode(envelope['cipherText'] as String);
    cipherText[cipherText.length ~/ 2] ^= 0x01;
    envelope['cipherText'] = base64Encode(cipherText);
    await file.writeAsString(jsonEncode(envelope), flush: true);

    expect(
      () => repository.loadMappings('doc_002'),
      throwsA(isA<VaultIntegrityException>()),
    );
  });

  test('empty mappings remove the document Vault record', () async {
    await repository.saveMappings(
      'doc_003',
      const [
        ReplacementMapping(
          token: '[[PG_PERSON_001]]',
          entityType: 'PERSON',
          originalText: 'Jane Doe',
        ),
      ],
    );
    expect(await repository.contains('doc_003'), isTrue);

    await repository.saveMappings('doc_003', const []);

    expect(await repository.contains('doc_003'), isFalse);
    expect(await repository.loadMappings('doc_003'), isEmpty);
  });

  test('destroy deletes Vault files and the platform key', () async {
    await repository.saveMappings(
      'doc_004',
      const [
        ReplacementMapping(
          token: '[[PG_PERSON_001]]',
          entityType: 'PERSON',
          originalText: 'Jane Doe',
        ),
      ],
    );

    await repository.destroy();

    expect(await repository.contains('doc_004'), isFalse);
    expect(cryptor.keyDeleted, isTrue);
  });

  test('document ids cannot escape the Vault directory', () {
    expect(
      () => repository.contains('../outside'),
      throwsArgumentError,
    );
  });
}

class _TestVaultCryptor implements VaultCryptor {
  _TestVaultCryptor(this.directory);

  final Directory directory;
  var _nonceCounter = 0;
  bool keyDeleted = false;

  @override
  Future<Directory> vaultDirectory() async => directory;

  @override
  Future<VaultCiphertext> encrypt(
    List<int> clearText, {
    required List<int> aad,
  }) async {
    _nonceCounter += 1;
    final nonce = List<int>.filled(12, 0)..[11] = _nonceCounter & 0xff;
    final encrypted = clearText.map((value) => value ^ 0xa5).toList(growable: true);
    final checksum = _checksum(clearText, aad, nonce);
    encrypted.addAll(_int32(checksum));
    return VaultCiphertext(nonce: nonce, cipherText: encrypted);
  }

  @override
  Future<List<int>> decrypt(
    VaultCiphertext ciphertext, {
    required List<int> aad,
  }) async {
    if (ciphertext.cipherText.length < 4) {
      throw const VaultAuthenticationException();
    }
    final body = ciphertext.cipherText.sublist(0, ciphertext.cipherText.length - 4);
    final expectedChecksum = _fromInt32(
      ciphertext.cipherText.sublist(ciphertext.cipherText.length - 4),
    );
    final clearText = body.map((value) => value ^ 0xa5).toList(growable: false);
    if (_checksum(clearText, aad, ciphertext.nonce) != expectedChecksum) {
      throw const VaultAuthenticationException();
    }
    return clearText;
  }

  @override
  Future<void> deleteKey() async {
    keyDeleted = true;
  }

  static int _checksum(List<int> clearText, List<int> aad, List<int> nonce) {
    var hash = 0x811c9dc5;
    for (final value in <int>[...clearText, ...aad, ...nonce]) {
      hash ^= value;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash;
  }

  static List<int> _int32(int value) => [
        (value >> 24) & 0xff,
        (value >> 16) & 0xff,
        (value >> 8) & 0xff,
        value & 0xff,
      ];

  static int _fromInt32(List<int> bytes) =>
      ((bytes[0] << 24) |
          (bytes[1] << 16) |
          (bytes[2] << 8) |
          bytes[3]) &
      0xffffffff;
}
