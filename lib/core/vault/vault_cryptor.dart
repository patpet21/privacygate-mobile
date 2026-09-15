import 'dart:io';

class VaultCiphertext {
  const VaultCiphertext({
    required this.nonce,
    required this.cipherText,
  });

  final List<int> nonce;
  final List<int> cipherText;
}

class VaultAuthenticationException implements Exception {
  const VaultAuthenticationException([this.message = 'Vault authentication failed']);

  final String message;

  @override
  String toString() => 'VaultAuthenticationException: $message';
}

abstract interface class VaultCryptor {
  Future<Directory> vaultDirectory();

  Future<VaultCiphertext> encrypt(
    List<int> clearText, {
    required List<int> aad,
  });

  Future<List<int>> decrypt(
    VaultCiphertext ciphertext, {
    required List<int> aad,
  });

  Future<void> deleteKey();
}
