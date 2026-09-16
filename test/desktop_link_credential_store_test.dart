import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:privacygate/core/desktop_link/desktop_link_credential_store.dart';
import 'package:privacygate/core/desktop_link/desktop_link_models.dart';
import 'package:privacygate/core/vault/vault_cryptor.dart';

void main() {
  test('Desktop Link credential is encrypted at rest', () async {
    final directory = await Directory.systemTemp.createTemp('pg-link-test-');
    addTearDown(() => directory.delete(recursive: true));
    final cryptor = _TestCryptor(directory);
    final store = DesktopLinkCredentialStore(cryptor: cryptor);
    const credential = DesktopLinkCredential(
      endpoint: 'https://192.168.1.5:8767',
      mobileToken: 'super-secret-token',
      certificatePem: 'CERTIFICATE-PEM',
      detectionPackSha256: 'pack-sha',
      clientId: 'mobile-client-0001',
      clientName: 'Test phone',
    );

    await store.save(credential);
    final file = File('${directory.path}${Platform.pathSeparator}desktop-link.pglink');
    final raw = await file.readAsString();
    expect(raw, isNot(contains('super-secret-token')));
    expect(raw, isNot(contains('CERTIFICATE-PEM')));

    final loaded = await store.load();
    expect(loaded?.mobileToken, credential.mobileToken);
    expect(loaded?.endpoint, credential.endpoint);
    expect(loaded?.certificatePem, credential.certificatePem);
  });
}

class _TestCryptor implements VaultCryptor {
  _TestCryptor(this.directory);
  final Directory directory;

  @override
  Future<Directory> vaultDirectory() async => directory;

  @override
  Future<VaultCiphertext> encrypt(List<int> clearText, {required List<int> aad}) async =>
      VaultCiphertext(nonce: const [7, 8, 9], cipherText: clearText.map((value) => value ^ 0x5A).toList());

  @override
  Future<List<int>> decrypt(VaultCiphertext ciphertext, {required List<int> aad}) async =>
      ciphertext.cipherText.map((value) => value ^ 0x5A).toList();

  @override
  Future<void> deleteKey() async {}
}
