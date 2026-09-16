import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'desktop_link_credential_store.dart';
import 'desktop_link_models.dart';
import 'desktop_link_status.dart';
import 'desktop_protected_copy.dart';
import 'desktop_remote_relay_client.dart';

class DesktopProtectedCopyException implements Exception {
  const DesktopProtectedCopyException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DesktopProtectedCopyClient {
  DesktopProtectedCopyClient(this.credentials);

  final DesktopLinkCredentialStore credentials;
  final DesktopRemoteRelayClient _remoteRelay = const DesktopRemoteRelayClient();

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
        'Desktop returned an invalid Library transfer list.',
      );
    }
    return List<DesktopProtectedCopyGrant>.unmodifiable(
      rawGrants.map((item) {
        if (item is! Map) {
          throw const FormatException('Invalid Desktop Library grant.');
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
        'Desktop Library grant ID is invalid.',
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

    DesktopLinkPresence.set(DesktopLinkStatus.checking);
    try {
      final payload = await _getLocalJson(
        endpoint: credential.endpoint,
        path: path,
        pinnedCertificatePem: credential.certificatePem,
        bearerToken: credential.mobileToken,
      );
      DesktopLinkPresence.set(DesktopLinkStatus.connectedLocal);
      return payload;
    } on SocketException {
      return _getRemoteJson(credential, path);
    } on TimeoutException {
      return _getRemoteJson(credential, path);
    } on HandshakeException {
      return _getRemoteJson(credential, path);
    } on FormatException catch (error) {
      throw DesktopProtectedCopyException(error.message);
    }
  }

  Future<Map<String, Object?>> _getRemoteJson(
    DesktopLinkCredential credential,
    String path,
  ) async {
    if (!credential.hasRemoteRelay) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw const DesktopProtectedCopyException(
        'Desktop is offline or outside the local network, and Remote Device Trust is not provisioned yet.',
      );
    }
    try {
      final payload = await _remoteRelay.requestJson(
        credential: credential,
        method: 'GET',
        path: path,
        body: const {},
      );
      DesktopLinkPresence.set(DesktopLinkStatus.connectedRemote);
      return payload;
    } on DesktopRemoteRelayException catch (error) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DesktopProtectedCopyException(error.message);
    } on FormatException catch (error) {
      throw DesktopProtectedCopyException(error.message);
    }
  }

  Future<Map<String, Object?>> _getLocalJson({
    required String endpoint,
    required String path,
    required String pinnedCertificatePem,
    required String bearerToken,
  }) async {
    final base = Uri.parse(endpoint);
    if (base.scheme != 'https' || base.host.isEmpty || !base.hasPort) {
      throw const DesktopProtectedCopyException(
        'Desktop endpoint must be HTTPS with an explicit port.',
      );
    }
    final expectedPem = _normalizePem(pinnedCertificatePem);
    final securityContext = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(utf8.encode(pinnedCertificatePem));
    final client = HttpClient(context: securityContext)
      ..connectionTimeout = const Duration(seconds: 2);
    client.badCertificateCallback = (certificate, host, port) =>
        host == base.host &&
        port == base.port &&
        _normalizePem(certificate.pem) == expectedPem;

    try {
      final uri = base.replace(path: path, fragment: null);
      final request = await client.getUrl(uri).timeout(const Duration(seconds: 3));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.acceptHeader, 'application/json');
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      request.headers.set(
        HttpHeaders.authorizationHeader,
        'Bearer $bearerToken',
      );

      final response = await request.close().timeout(const Duration(seconds: 30));
      final certificate = response.certificate;
      if (certificate == null ||
          _normalizePem(certificate.pem) != expectedPem) {
        throw HandshakeException(
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
      return payload;
    } finally {
      client.close(force: true);
    }
  }

  static String _normalizePem(String value) =>
      value.replaceAll('\r\n', '\n').trim();
}
