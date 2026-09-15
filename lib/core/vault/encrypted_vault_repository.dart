import 'dart:convert';
import 'dart:io';

import '../domain/replacement_mapping.dart';
import 'platform_vault_cryptor.dart';
import 'vault_cryptor.dart';

class VaultIntegrityException implements Exception {
  const VaultIntegrityException([this.message = 'Encrypted Vault data is invalid']);

  final String message;

  @override
  String toString() => 'VaultIntegrityException: $message';
}

class EncryptedVaultRepository {
  EncryptedVaultRepository({
    required Directory directory,
    required VaultCryptor cryptor,
  })  : _directory = directory,
        _cryptor = cryptor;

  static const String format = 'privacygate-mobile-vault-v1';
  static const String algorithm = 'AES-256-GCM';
  static final RegExp _documentIdPattern = RegExp(r'^[A-Za-z0-9_-]{1,128}$');

  final Directory _directory;
  final VaultCryptor _cryptor;

  static Future<EncryptedVaultRepository> openDefault({
    VaultCryptor? cryptor,
  }) async {
    final resolvedCryptor = cryptor ?? PlatformVaultCryptor();
    final directory = await resolvedCryptor.vaultDirectory();
    return EncryptedVaultRepository(
      directory: directory,
      cryptor: resolvedCryptor,
    );
  }

  Future<void> saveMappings(
    String documentId,
    Iterable<ReplacementMapping> mappings,
  ) async {
    _validateDocumentId(documentId);
    final normalizedMappings = _normalizeMappings(mappings);
    if (normalizedMappings.isEmpty) {
      await delete(documentId);
      return;
    }

    await _directory.create(recursive: true);
    final clearPayload = utf8.encode(
      jsonEncode(<String, dynamic>{
        'documentId': documentId,
        'mappings': normalizedMappings
            .map(
              (mapping) => <String, String>{
                'token': mapping.token,
                'entityType': mapping.entityType,
                'originalText': mapping.originalText,
              },
            )
            .toList(growable: false),
      }),
    );
    final encrypted = await _cryptor.encrypt(
      clearPayload,
      aad: _aad(documentId),
    );
    final envelope = <String, dynamic>{
      'format': format,
      'algorithm': algorithm,
      'documentId': documentId,
      'nonce': base64Encode(encrypted.nonce),
      'cipherText': base64Encode(encrypted.cipherText),
    };

    await _fileFor(documentId).writeAsString(
      jsonEncode(envelope),
      flush: true,
    );
  }

  Future<List<ReplacementMapping>> loadMappings(String documentId) async {
    _validateDocumentId(documentId);
    final file = _fileFor(documentId);
    if (!await file.exists()) return const <ReplacementMapping>[];

    try {
      final envelopeValue = jsonDecode(await file.readAsString());
      if (envelopeValue is! Map<String, dynamic>) {
        throw const VaultIntegrityException('Vault envelope must be an object');
      }
      if (envelopeValue['format'] != format ||
          envelopeValue['algorithm'] != algorithm ||
          envelopeValue['documentId'] != documentId) {
        throw const VaultIntegrityException('Vault envelope metadata does not match');
      }

      final nonce = base64Decode(_requireString(envelopeValue, 'nonce'));
      final cipherText = base64Decode(_requireString(envelopeValue, 'cipherText'));
      final clearPayload = await _cryptor.decrypt(
        VaultCiphertext(nonce: nonce, cipherText: cipherText),
        aad: _aad(documentId),
      );
      final payloadValue = jsonDecode(utf8.decode(clearPayload));
      if (payloadValue is! Map<String, dynamic> ||
          payloadValue['documentId'] != documentId) {
        throw const VaultIntegrityException('Vault payload metadata does not match');
      }
      final rawMappings = payloadValue['mappings'];
      if (rawMappings is! List) {
        throw const VaultIntegrityException('Vault payload mappings are invalid');
      }

      final mappings = <ReplacementMapping>[];
      final tokens = <String>{};
      for (final rawMapping in rawMappings) {
        if (rawMapping is! Map) {
          throw const VaultIntegrityException('Vault mapping entry is invalid');
        }
        final token = rawMapping['token'];
        final entityType = rawMapping['entityType'];
        final originalText = rawMapping['originalText'];
        if (token is! String ||
            token.isEmpty ||
            entityType is! String ||
            entityType.isEmpty ||
            originalText is! String ||
            !tokens.add(token)) {
          throw const VaultIntegrityException('Vault mapping fields are invalid');
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
    } on VaultAuthenticationException catch (error) {
      throw VaultIntegrityException(error.message);
    } on VaultIntegrityException {
      rethrow;
    } on FormatException catch (error) {
      throw VaultIntegrityException('Malformed Vault data: ${error.message}');
    } on TypeError {
      throw const VaultIntegrityException('Malformed Vault data');
    }
  }

  Future<bool> contains(String documentId) async {
    _validateDocumentId(documentId);
    return _fileFor(documentId).exists();
  }

  Future<void> delete(String documentId) async {
    _validateDocumentId(documentId);
    final file = _fileFor(documentId);
    if (await file.exists()) await file.delete();
  }

  Future<void> destroy() async {
    if (await _directory.exists()) {
      await for (final entity in _directory.list()) {
        if (entity is File && entity.path.endsWith('.pgvault')) {
          await entity.delete();
        }
      }
    }
    await _cryptor.deleteKey();
  }

  File _fileFor(String documentId) => File(
        '${_directory.path}${Platform.pathSeparator}$documentId.pgvault',
      );

  static List<int> _aad(String documentId) => utf8.encode('$format\u0000$documentId');

  static String _requireString(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is! String || value.isEmpty) {
      throw VaultIntegrityException('Vault envelope is missing $key');
    }
    return value;
  }

  static List<ReplacementMapping> _normalizeMappings(
    Iterable<ReplacementMapping> mappings,
  ) {
    final result = mappings.toList(growable: false)
      ..sort((left, right) => left.token.compareTo(right.token));
    final tokens = <String>{};
    for (final mapping in result) {
      if (mapping.token.isEmpty || mapping.entityType.isEmpty) {
        throw ArgumentError('Vault mappings require token and entity type');
      }
      if (!tokens.add(mapping.token)) {
        throw ArgumentError.value(mapping.token, 'token', 'Duplicate Vault token');
      }
    }
    return result;
  }

  static void _validateDocumentId(String documentId) {
    if (!_documentIdPattern.hasMatch(documentId)) {
      throw ArgumentError.value(
        documentId,
        'documentId',
        'Use 1-128 letters, numbers, underscores, or hyphens',
      );
    }
  }
}
