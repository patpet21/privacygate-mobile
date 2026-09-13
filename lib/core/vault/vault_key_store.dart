abstract interface class VaultKeyStore {
  Future<String> ensureVaultKeyId();
  Future<void> deleteVaultKey();
}
