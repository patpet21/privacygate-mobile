import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'desktop_link_credential_store.dart';
import 'desktop_link_status.dart';
import 'desktop_protected_copy.dart';

class DesktopProtectedCopyException implements Exception {
  const DesktopProtectedCopyException(this.message);

  final String message;

  @override
  String toString() => 'DesktopProtectedCopyException: $message';
}

class DesktopProtectedCopyClient {
  DesktopProtectedCopyClient(this.credentials);

  final DesktopLinkCredentialStore credentials;

  Future<bool> hasCredential() => credentials.contains();

  Future<List<DesktopProtectedCopyGrant>> listGrants() async {
    final payload = await _getJson('/v1/mobile/library/grants');
    if (payload['automatic_sync'] != false) {
      throw const DesktopProtectedCopyException(
        'Desktop returned an unsafe automatic-sync contract.',
      );
    }
    final rawGrants = payload['grants'];
    if (rawGrants is! List) {
      throw const DesktopProtectedCopyException(
        'Desktop returned an invalid protected-copy list.',
      );
    }
    return List<DesktopProtectedCopyGrant>.unmodifiable(
      rawGrants.map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid protected-copy grant.');
        }
        return DesktopProtectedCopyGrant.fromJson(
          Map<String, Object?>.from(item),
        );
      }),
    );
  }

  Future<DesktopProtectedCopyDocument> fetch(String grantId) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{12,128}$').hasMatch(grantId)) {
      throw const DesktopProtectedCopyException(
        'Protected-copy grant ID is invalid.',
      );
    }
    final payload = await _getJson(
      '/v1/mobile/library/grants/${Uri.encodeComponent(grantId)}',
    );
    return DesktopProtectedCopyDocument.fromJson(payload);
  }

  Future<Map<String, Object?>> _getJson(String path) async {
    final credential = await credentials.load();
    if (credential == null) {
      DesktopLinkPresence.set(DesktopLinkStatus.unpaired);
      throw const DesktopProtectedCopyException(
        'No paired Desktop is configured.',
      );
    }

    final base = Uri.parse(credential.endpoint);
    if (base.scheme != 'https' || base.host.isEmpty || !base.hasPort) {
      throw const DesktopProtectedCopyException(
        'Desktop endpoint must be HTTPS with an explicit port.',
      );
    }
    final expectedPem = _normalizePem(credential.certificatePem);
    final securityContext = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(utf8.encode(credential.certificatePem));
    final client = HttpClient(context: securityContext)
      ..connectionTimeout = const Duration(seconds: 2);
    client.badCertificateCallback = (certificate, host, port) =>
        host == base.host &&
        port == base.port &&
        _normalizePem(certificate.pem) == expectedPem;

    DesktopLinkPresence.set(DesktopLinkStatus.checking);
    try {
      final uri = base.replace(path: path, fragment: null);
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 3));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer ${credential.mobileToken}',
      );

      final response = await request.close().timeout(const Duration(seconds: 30));
      final certificate = response.certificate;
      if (certificate == null ||
          _normalizePem(certificate.pem) != expectedPem) {
        throw const HandshakeException(
          'Desktop certificate pin did not match pairing data.',
        );
      }
      final text = await response
          .transform(utf8.decoder)
          .join()
          .timeout(const Duration(seconds: 30));
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const DesktopProtectedCopyException(
          'Desktop returned invalid JSON.',
        );
      }
      final payload = Map<String, Object?>.from(decoded);
      if (response.statusCode != HttpStatus.ok) {
        final error = payload['error'] ?? 'http_${response.statusCode}';
        final message = payload['message'];
        final detail = message is String && message.isNotEmpty
            ? ' — $message'
            : '';
        throw DesktopProtectedCopyException(
          'Desktop rejected request: $error$detail',
        );
      }
      DesktopLinkPresence.set(DesktopLinkStatus.connected);
      return payload;
    } on SocketException catch (error) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DesktopProtectedCopyException(
        'Desktop is unreachable on the local network: $error',
      );
    } on TimeoutException catch (error) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DesktopProtectedCopyException('Desktop request timed out: $error');
    } on HandshakeException catch (error) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DesktopProtectedCopyException(
        'Desktop TLS identity could not be verified: $error',
      );
    } on FormatException catch (error) {
      throw DesktopProtectedCopyException(error.message);
    } finally {
      client.close(force: true);
    }
  }

  static String _normalizePem(String value) =>
      value.replaceAll('\r\n', '\n').trim();
}
