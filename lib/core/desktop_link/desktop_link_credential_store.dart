import 'dart:convert';
import 'dart:io';

import '../vault/platform_vault_cryptor.dart';
import '../vault/vault_cryptor.dart';
import 'desktop_link_models.dart';

class DesktopLinkCredentialStore {
  DesktopLinkCredentialStore({VaultCryptor? cryptor})
      : _cryptor = cryptor ?? PlatformVaultCryptor();

  static const _format = 'privacygate-mobile-desktop-link-v1';
  static final List<int> _aad = utf8.encode(_format);
  final VaultCryptor _cryptor;

  Future<File> _file() async {
    final directory = await _cryptor.vaultDirectory();
    await directory.create(recursive: true);
    return File('${directory.path}${Platform.pathSeparator}desktop-link.pglink');
  }

  Future<bool> contains() async => (await _file()).exists();

  Future<void> save(DesktopLinkCredential credential) async {
    final clearText = utf8.encode(jsonEncode(credential.toJson()));
    final encrypted = await _cryptor.encrypt(clearText, aad: _aad);
    final envelope = {
      'format': _format,
      'nonce': base64Encode(encrypted.nonce),
      'ciphertext': base64Encode(encrypted.cipherText),
    };
    final file = await _file();
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(jsonEncode(envelope), flush: true);
    if (await file.exists()) await file.delete();
    await temporary.rename(file.path);
  }

  Future<DesktopLinkCredential?> load() async {
    final file = await _file();
    if (!await file.exists()) return null;
    try {
      final decoded = jsonDecode(await file.readAsString());
      if (decoded is! Map) {
        throw const FormatException('Desktop Link credential envelope is invalid.');
      }
      final envelope = Map<String, Object?>.from(decoded);
      if (envelope['format'] != _format) {
        throw const FormatException('Desktop Link credential envelope is invalid.');
      }
      final nonce = envelope['nonce'];
      final ciphertext = envelope['ciphertext'];
      if (nonce is! String || ciphertext is! String) {
        throw const FormatException('Desktop Link credential envelope is incomplete.');
      }
      final clearText = await _cryptor.decrypt(
        VaultCiphertext(
          nonce: base64Decode(nonce),
          cipherText: base64Decode(ciphertext),
        ),
        aad: _aad,
      );
      final payload = jsonDecode(utf8.decode(clearText));
      if (payload is! Map) {
        throw const FormatException('Desktop Link credential payload is invalid.');
      }
      return DesktopLinkCredential.fromJson(Map<String, Object?>.from(payload));
    } on VaultAuthenticationException {
      rethrow;
    } on FormatException {
      rethrow;
    } catch (error) {
      throw FormatException('Desktop Link credential could not be decoded: $error');
    }
  }

  Future<void> delete() async {
    final file = await _file();
    if (await file.exists()) await file.delete();
  }
}
