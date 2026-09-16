import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../detection/detection_engine.dart';
import '../detection/detection_engine_router.dart';
import '../domain/privacy_finding.dart';
import 'desktop_link_credential_store.dart';
import 'desktop_link_models.dart';

class DesktopLinkProtocolException implements Exception {
  const DesktopLinkProtocolException(this.message);
  final String message;
  @override
  String toString() => 'DesktopLinkProtocolException: $message';
}

class DesktopLinkClient {
  DesktopLinkClient(this.credentials);

  final DesktopLinkCredentialStore credentials;
  DateTime? _unavailableUntil;

  Future<bool> canAttempt() async {
    final blockedUntil = _unavailableUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) return false;
    return credentials.contains();
  }

  Future<DesktopLinkCredential> pair(
    DesktopLinkPairingBundle bundle, {
    String? clientId,
    String clientName = 'PrivacyGate Mobile',
  }) async {
    if (DateTime.now().toUtc().isAfter(bundle.expiresAt)) {
      throw const DesktopLinkProtocolException('Desktop pairing code has expired.');
    }
    final id = clientId ?? _newClientId();
    Object? lastError;
    for (final endpoint in bundle.endpoints) {
      try {
        final response = await _postJson(
          endpoint: endpoint,
          path: '/v1/mobile/pair',
          pinnedCertificatePem: bundle.certificatePem,
          body: {
            'code': bundle.pairingCode,
            'client_id': id,
            'client_name': clientName,
          },
        );
        final token = response['mobile_token'];
        final packSha = response['detection_pack_sha256'];
        if (token is! String || token.isEmpty || packSha is! String || packSha.isEmpty) {
          throw const DesktopLinkProtocolException('Desktop pairing response is incomplete.');
        }
        if (packSha != bundle.detectionPackSha256) {
          throw const DesktopLinkProtocolException(
            'Desktop detection pack changed during pairing.',
          );
        }
        final credential = DesktopLinkCredential(
          endpoint: endpoint,
          mobileToken: token,
          certificatePem: bundle.certificatePem,
          detectionPackSha256: packSha,
          clientId: id,
          clientName: clientName,
        );
        await credentials.save(credential);
        _unavailableUntil = null;
        return credential;
      } catch (error) {
        lastError = error;
      }
    }
    throw DesktopLinkProtocolException('Could not pair with Desktop: $lastError');
  }

  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async {
    final credential = await credentials.load();
    if (credential == null) {
      throw const DetectionEngineUnavailableException('No paired Desktop is configured.');
    }
    try {
      final response = await _postJson(
        endpoint: credential.endpoint,
        path: '/v1/mobile/analyze',
        pinnedCertificatePem: credential.certificatePem,
        bearerToken: credential.mobileToken,
        body: {
          'text': request.text,
          'profile_key': request.profileKey,
          'scope_key': request.scopeKey,
          'language': request.scanLanguage,
          'confidence_threshold': request.confidenceThreshold,
        },
      );
      final responsePackSha = response['detection_pack_sha256'];
      if (responsePackSha != credential.detectionPackSha256) {
        throw const DesktopLinkProtocolException(
          'Desktop detection pack no longer matches the paired version.',
        );
      }
      final rawFindings = response['findings'];
      if (rawFindings is! List) {
        throw const DesktopLinkProtocolException('Desktop analyze response has no findings array.');
      }
      final findings = <PrivacyFinding>[];
      for (var index = 0; index < rawFindings.length; index += 1) {
        final item = rawFindings[index];
        if (item is! Map) {
          throw const DesktopLinkProtocolException('Desktop finding is invalid.');
        }
        final entityType = item['entity_type'];
        final start = item['start'];
        final end = item['end'];
        final score = item['score'];
        if (entityType is! String || start is! int || end is! int || score is! num) {
          throw const DesktopLinkProtocolException('Desktop finding fields are invalid.');
        }
        if (start < 0 || end <= start || end > request.text.length) {
          throw const DesktopLinkProtocolException('Desktop finding range is invalid.');
        }
        findings.add(
          PrivacyFinding(
            findingId: 'desktop-$start-$end-$index',
            entityType: entityType,
            text: request.text.substring(start, end),
            start: start,
            end: end,
            score: score.toDouble(),
            pageNumber: 1,
            context: _context(request.text, start, end),
          ),
        );
      }
      _unavailableUntil = null;
      return List.unmodifiable(findings);
    } on SocketException catch (error) {
      _markUnavailable();
      throw DetectionEngineUnavailableException('Desktop is unreachable: $error');
    } on HandshakeException catch (error) {
      _markUnavailable();
      throw DetectionEngineUnavailableException('Desktop TLS connection failed: $error');
    } on TimeoutException catch (error) {
      _markUnavailable();
      throw DetectionEngineUnavailableException('Desktop timed out: $error');
    }
  }

  void _markUnavailable() {
    _unavailableUntil = DateTime.now().add(const Duration(seconds: 5));
  }

  Future<Map<String, Object?>> _postJson({
    required String endpoint,
    required String path,
    required String pinnedCertificatePem,
    required Map<String, Object?> body,
    String? bearerToken,
  }) async {
    final base = Uri.parse(endpoint);
    if (base.scheme != 'https' || base.host.isEmpty || !base.hasPort) {
      throw const DesktopLinkProtocolException('Desktop endpoint must be HTTPS with an explicit port.');
    }
    final expectedPem = _normalizePem(pinnedCertificatePem);
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 2);
    client.badCertificateCallback = (certificate, host, port) =>
        host == base.host && port == base.port && _normalizePem(certificate.pem) == expectedPem;
    try {
      final uri = base.replace(path: path, query: null, fragment: null);
      final request = await client.postUrl(uri).timeout(const Duration(seconds: 3));
      request.headers.contentType = ContentType.json;
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      if (bearerToken != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      }
      request.write(jsonEncode(body));
      final response = await request.close().timeout(const Duration(seconds: 5));
      final certificate = response.certificate;
      if (certificate == null || _normalizePem(certificate.pem) != expectedPem) {
        throw HandshakeException('Desktop certificate pin did not match pairing data.');
      }
      final text = await response.transform(utf8.decoder).join();
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const DesktopLinkProtocolException('Desktop returned invalid JSON.');
      }
      final payload = Map<String, Object?>.from(decoded);
      if (response.statusCode != HttpStatus.ok) {
        final error = payload['error'] ?? 'http_${response.statusCode}';
        throw DesktopLinkProtocolException('Desktop rejected request: $error');
      }
      return payload;
    } finally {
      client.close(force: true);
    }
  }

  static String _normalizePem(String value) => value.replaceAll('\r\n', '\n').trim();

  static String _newClientId() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final hex = bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join();
    return 'mobile-$hex';
  }

  static String _context(String text, int start, int end) {
    final left = max(0, start - 34);
    final right = min(text.length, end + 34);
    return text.substring(left, right);
  }
}
