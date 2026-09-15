import 'dart:io';

import 'package:flutter/services.dart';

import 'vault_cryptor.dart';

class PlatformVaultCryptor implements VaultCryptor {
  static const MethodChannel _channel = MethodChannel(
    'com.aipmlab.privacygate/vault',
  );

  @override
  Future<Directory> vaultDirectory() async {
    final path = await _channel.invokeMethod<String>('vaultDirectoryPath');
    if (path == null || path.trim().isEmpty) {
      throw StateError('Platform Vault directory is unavailable');
    }
    return Directory(path);
  }

  @override
  Future<VaultCiphertext> encrypt(
    List<int> clearText, {
    required List<int> aad,
  }) async {
    final response = await _channel.invokeMapMethod<String, dynamic>(
      'encrypt',
      <String, dynamic>{
        'clearText': Uint8List.fromList(clearText),
        'aad': Uint8List.fromList(aad),
      },
    );
    if (response == null) {
      throw StateError('Platform Vault encryption returned no result');
    }
    return VaultCiphertext(
      nonce: _readBytes(response['nonce'], 'nonce'),
      cipherText: _readBytes(response['cipherText'], 'cipherText'),
    );
  }

  @override
  Future<List<int>> decrypt(
    VaultCiphertext ciphertext, {
    required List<int> aad,
  }) async {
    try {
      final clearText = await _channel.invokeMethod<Uint8List>(
        'decrypt',
        <String, dynamic>{
          'nonce': Uint8List.fromList(ciphertext.nonce),
          'cipherText': Uint8List.fromList(ciphertext.cipherText),
          'aad': Uint8List.fromList(aad),
        },
      );
      if (clearText == null) {
        throw StateError('Platform Vault decryption returned no result');
      }
      return clearText;
    } on PlatformException catch (error) {
      if (error.code == 'vault_auth_failed') {
        throw VaultAuthenticationException(error.message ?? 'Vault authentication failed');
      }
      rethrow;
    }
  }

  @override
  Future<void> deleteKey() => _channel.invokeMethod<void>('deleteKey');

  static List<int> _readBytes(dynamic value, String field) {
    if (value is Uint8List) return value;
    if (value is List<int>) return value;
    throw StateError('Platform Vault response is missing $field bytes');
  }
}
