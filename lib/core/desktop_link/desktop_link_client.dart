import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import '../detection/detection_engine.dart';
import '../detection/detection_engine_router.dart';
import '../domain/privacy_finding.dart';
import 'desktop_link_credential_store.dart';
import 'desktop_link_models.dart';
import 'desktop_link_status.dart';
import 'desktop_remote_relay_client.dart';

class DesktopLinkProtocolException implements Exception {
  const DesktopLinkProtocolException(this.message);
  final String message;
  @override
  String toString() => 'DesktopLinkProtocolException: $message';
}

class DesktopLinkClient {
  DesktopLinkClient(this.credentials);

  final DesktopLinkCredentialStore credentials;
  final DesktopRemoteRelayClient _remoteRelay = const DesktopRemoteRelayClient();

  // Explicit, session-scoped consent. Pairing alone never sends documents.
  bool analysisEnabled = false;
  DateTime? _unavailableUntil;

  Future<bool> canAttempt() async {
    if (!analysisEnabled) return false;
    final blockedUntil = _unavailableUntil;
    if (blockedUntil != null && DateTime.now().isBefore(blockedUntil)) return false;
    return credentials.contains();
  }

  Future<DesktopLinkStatus> refreshConnectionState() async {
    if (!await credentials.contains()) {
      DesktopLinkPresence.set(DesktopLinkStatus.unpaired);
      return DesktopLinkStatus.unpaired;
    }
    try {
      await checkConnection();
    } catch (_) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
    }
    return DesktopLinkPresence.value;
  }

  Future<bool> checkConnection() async {
    var credential = await credentials.load();
    if (credential == null) {
      DesktopLinkPresence.set(DesktopLinkStatus.unpaired);
      return false;
    }
    DesktopLinkPresence.set(DesktopLinkStatus.checking);

    try {
      final response = await _postJson(
        endpoint: credential.endpoint,
        path: '/v1/mobile/status',
        pinnedCertificatePem: credential.certificatePem,
        bearerToken: credential.mobileToken,
        body: const {},
        method: 'GET',
      );
      final paired = response['paired'] == true;
      if (!paired) {
        DesktopLinkPresence.set(DesktopLinkStatus.offline);
        return false;
      }
      credential = await _applyStatusUpdates(credential, response);
      DesktopLinkPresence.set(DesktopLinkStatus.connectedLocal);
      return true;
    } on SocketException catch (_) {
      return _checkRemote(credential);
    } on TimeoutException catch (_) {
      return _checkRemote(credential);
    } on HandshakeException catch (_) {
      return _checkRemote(credential);
    }
  }

  Future<bool> _checkRemote(DesktopLinkCredential credential) async {
    if (!credential.hasRemoteRelay) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      return false;
    }
    try {
      final response = await _remoteRelay.requestJson(
        credential: credential,
        method: 'GET',
        path: '/v1/mobile/status',
        body: const {},
      );
      final paired = response['paired'] == true;
      if (!paired) {
        DesktopLinkPresence.set(DesktopLinkStatus.offline);
        return false;
      }
      await _applyStatusUpdates(credential, response);
      DesktopLinkPresence.set(DesktopLinkStatus.connectedRemote);
      return true;
    } on DesktopRemoteRelayException {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      return false;
    }
  }

  Future<DesktopLinkCredential> _applyStatusUpdates(
    DesktopLinkCredential credential,
    Map<String, Object?> response,
  ) async {
    var updated = credential;
    final serverName = response['client_name'];
    if (serverName is String &&
        serverName.trim().isNotEmpty &&
        serverName != updated.clientName) {
      updated = updated.copyWith(clientName: serverName.trim());
    }
    final remoteRaw = response['remote_relay'];
    if (remoteRaw is Map && remoteRaw.isNotEmpty) {
      updated = updated.withRemoteRelay(Map<String, Object?>.from(remoteRaw));
    }
    if (!_sameCredential(updated, credential)) await credentials.save(updated);
    return updated;
  }

  Future<DesktopLinkCredential> renameDevice(String newName) async {
    final credential = await credentials.load();
    if (credential == null) {
      DesktopLinkPresence.set(DesktopLinkStatus.unpaired);
      throw const DesktopLinkProtocolException('No paired Desktop is configured.');
    }
    final normalized = newName.trim();
    if (normalized.isEmpty) {
      throw const DesktopLinkProtocolException('Device name cannot be empty.');
    }
    if (normalized.length > 80) {
      throw const DesktopLinkProtocolException(
        'Device name cannot exceed 80 characters.',
      );
    }
    DesktopLinkPresence.set(DesktopLinkStatus.checking);
    final response = await _requestWithFallback(
      credential: credential,
      path: '/v1/mobile/device',
      body: {'client_name': normalized},
      method: 'PATCH',
    );
    final serverName = response['client_name'];
    if (serverName is! String || serverName.trim().isEmpty) {
      throw const DesktopLinkProtocolException(
        'Desktop returned an invalid device name.',
      );
    }
    final updated = credential.copyWith(clientName: serverName.trim());
    await credentials.save(updated);
    return updated;
  }

  Future<void> removeDevice() async {
    final credential = await credentials.load();
    if (credential == null) {
      await forget();
      return;
    }
    DesktopLinkPresence.set(DesktopLinkStatus.checking);
    final response = await _requestWithFallback(
      credential: credential,
      path: '/v1/mobile/device',
      body: const {},
      method: 'DELETE',
    );
    if (response['removed'] != true) {
      throw const DesktopLinkProtocolException(
        'Desktop did not remove this paired device.',
      );
    }
    await forget();
  }

  Future<void> forget() async {
    analysisEnabled = false;
    _unavailableUntil = null;
    await credentials.delete();
    DesktopLinkPresence.set(DesktopLinkStatus.unpaired);
  }

  Future<DesktopLinkCredential> pair(
    DesktopLinkPairingBundle bundle, {
    String? clientId,
    String clientName = 'PrivacyGate Mobile',
  }) async {
    if (DateTime.now().toUtc().isAfter(bundle.expiresAt)) {
      throw const DesktopLinkProtocolException('Desktop pairing code has expired.');
    }
    DesktopLinkPresence.set(DesktopLinkStatus.checking);
    final id = clientId ?? _newClientId();
    Object? lastError;
    for (final endpoint in bundle.endpoints) {
      Map<String, Object?> response;
      try {
        response = await _postJson(
          endpoint: endpoint,
          path: '/v1/mobile/pair',
          pinnedCertificatePem: bundle.certificatePem,
          body: {
            'code': bundle.pairingCode,
            'client_id': id,
            'client_name': clientName,
          },
        );
      } catch (error) {
        lastError = error;
        continue;
      }

      final packSha = response['detection_pack_sha256'];
      if (packSha is! String || packSha.isEmpty) {
        throw const DesktopLinkProtocolException('Desktop pairing response is incomplete.');
      }
      if (packSha != bundle.detectionPackSha256) {
        throw const DesktopLinkProtocolException(
          'Desktop detection pack changed during pairing.',
        );
      }

      var approval = response;
      var token = response['mobile_token'];
      if (token is! String || token.isEmpty) {
        final approvalRequired = response['approval_required'] == true;
        final requestId = response['pairing_request_id'];
        if (!approvalRequired || requestId is! String || requestId.isEmpty) {
          throw const DesktopLinkProtocolException(
            'Desktop did not provide a credential or an approval request.',
          );
        }
        approval = await _waitForDesktopApproval(
          endpoint: endpoint,
          requestId: requestId,
          bundle: bundle,
        );
        token = approval['mobile_token'];
      }
      if (token is! String || token.isEmpty) {
        throw const DesktopLinkProtocolException(
          'Desktop approved pairing but returned no credential.',
        );
      }

      var credential = DesktopLinkCredential(
        endpoint: endpoint,
        mobileToken: token,
        certificatePem: bundle.certificatePem,
        detectionPackSha256: packSha,
        clientId: id,
        clientName: clientName,
      );
      final remoteRaw = approval['remote_relay'];
      if (remoteRaw is Map && remoteRaw.isNotEmpty) {
        credential = credential.withRemoteRelay(
          Map<String, Object?>.from(remoteRaw),
        );
      }
      await credentials.save(credential);
      _unavailableUntil = null;
      DesktopLinkPresence.set(DesktopLinkStatus.connectedLocal);
      return credential;
    }
    DesktopLinkPresence.set(DesktopLinkStatus.offline);
    throw DesktopLinkProtocolException('Could not contact Desktop for pairing: $lastError');
  }

  Future<Map<String, Object?>> _waitForDesktopApproval({
    required String endpoint,
    required String requestId,
    required DesktopLinkPairingBundle bundle,
  }) async {
    final deadline = DateTime.now().add(const Duration(minutes: 5));
    Object? lastNetworkError;
    while (DateTime.now().isBefore(deadline)) {
      try {
        final response = await _postJson(
          endpoint: endpoint,
          path: '/v1/mobile/pair/status',
          pinnedCertificatePem: bundle.certificatePem,
          body: const {},
          method: 'GET',
          queryParameters: {'request_id': requestId},
        );
        final responsePackSha = response['detection_pack_sha256'];
        if (responsePackSha != bundle.detectionPackSha256) {
          throw const DesktopLinkProtocolException(
            'Desktop detection pack changed while pairing was awaiting approval.',
          );
        }
        final status = response['pairing_status'];
        if (status == 'approved') {
          final token = response['mobile_token'];
          if (token is! String || token.isEmpty) {
            throw const DesktopLinkProtocolException(
              'Desktop approved pairing but returned no credential.',
            );
          }
          return response;
        }
        if (status == 'denied') {
          throw const DesktopLinkProtocolException(
            'Pairing was denied on Desktop.',
          );
        }
        if (status == 'expired') {
          throw const DesktopLinkProtocolException(
            'Pairing approval expired. Create fresh pairing data on Desktop.',
          );
        }
        if (status != 'pending') {
          throw const DesktopLinkProtocolException(
            'Desktop returned an unknown pairing approval state.',
          );
        }
        lastNetworkError = null;
      } on SocketException catch (error) {
        lastNetworkError = error;
      } on TimeoutException catch (error) {
        lastNetworkError = error;
      }
      await Future<void>.delayed(const Duration(seconds: 1));
    }
    DesktopLinkPresence.set(DesktopLinkStatus.offline);
    throw DesktopLinkProtocolException(
      'Desktop approval timed out${lastNetworkError == null ? '' : ': $lastNetworkError'}',
    );
  }

  Future<List<PrivacyFinding>> analyze(DetectionRequest request) async {
    final credential = await credentials.load();
    if (credential == null) {
      DesktopLinkPresence.set(DesktopLinkStatus.unpaired);
      throw const DetectionEngineUnavailableException('No paired Desktop is configured.');
    }
    try {
      final response = await _requestWithFallback(
        credential: credential,
        path: '/v1/mobile/analyze',
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
      // Desktop uses Unicode code-point offsets; Dart strings use UTF-16.
      final offsets = <int>[0];
      for (final rune in request.text.runes) {
        offsets.add(offsets.last + (rune > 0xffff ? 2 : 1));
      }
      final findings = <PrivacyFinding>[];
      for (var index = 0; index < rawFindings.length; index += 1) {
        final item = rawFindings[index];
        if (item is! Map) {
          throw const DesktopLinkProtocolException('Desktop finding is invalid.');
        }
        final entityType = item['entity_type'];
        final rawStart = item['start'];
        final rawEnd = item['end'];
        final score = item['score'];
        if (entityType is! String || rawStart is! int || rawEnd is! int || score is! num) {
          throw const DesktopLinkProtocolException('Desktop finding fields are invalid.');
        }
        if (rawStart < 0 || rawEnd <= rawStart || rawEnd >= offsets.length ||
            !score.isFinite || score < 0 || score > 1) {
          throw const DesktopLinkProtocolException('Desktop finding range is invalid.');
        }
        final start = offsets[rawStart];
        final end = offsets[rawEnd];
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
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DetectionEngineUnavailableException('Desktop is unreachable: $error');
    } on HandshakeException catch (error) {
      _markUnavailable();
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DetectionEngineUnavailableException('Desktop TLS connection failed: $error');
    } on TimeoutException catch (error) {
      _markUnavailable();
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DetectionEngineUnavailableException('Desktop timed out: $error');
    } on DesktopRemoteRelayException catch (error) {
      _markUnavailable();
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw DetectionEngineUnavailableException(error.message);
    }
  }

  void _markUnavailable() {
    _unavailableUntil = DateTime.now().add(const Duration(seconds: 5));
  }

  Future<Map<String, Object?>> _requestWithFallback({
    required DesktopLinkCredential credential,
    required String path,
    required Map<String, Object?> body,
    String method = 'POST',
    Map<String, String>? queryParameters,
  }) async {
    try {
      final response = await _postJson(
        endpoint: credential.endpoint,
        path: path,
        pinnedCertificatePem: credential.certificatePem,
        bearerToken: credential.mobileToken,
        body: body,
        method: method,
        queryParameters: queryParameters,
      );
      DesktopLinkPresence.set(DesktopLinkStatus.connectedLocal);
      return response;
    } on SocketException {
      return _remoteFallback(
        credential: credential,
        path: path,
        body: body,
        method: method,
        queryParameters: queryParameters,
      );
    } on TimeoutException {
      return _remoteFallback(
        credential: credential,
        path: path,
        body: body,
        method: method,
        queryParameters: queryParameters,
      );
    } on HandshakeException {
      return _remoteFallback(
        credential: credential,
        path: path,
        body: body,
        method: method,
        queryParameters: queryParameters,
      );
    }
  }

  Future<Map<String, Object?>> _remoteFallback({
    required DesktopLinkCredential credential,
    required String path,
    required Map<String, Object?> body,
    required String method,
    Map<String, String>? queryParameters,
  }) async {
    if (!credential.hasRemoteRelay) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      throw const DesktopRemoteRelayException(
        'Desktop is outside the local network and Remote Device Trust is not provisioned yet.',
      );
    }
    try {
      final response = await _remoteRelay.requestJson(
        credential: credential,
        method: method,
        path: path,
        body: body,
        queryParameters: queryParameters,
      );
      DesktopLinkPresence.set(DesktopLinkStatus.connectedRemote);
      return response;
    } catch (_) {
      DesktopLinkPresence.set(DesktopLinkStatus.offline);
      rethrow;
    }
  }

  Future<Map<String, Object?>> _postJson({
    required String endpoint,
    required String path,
    required String pinnedCertificatePem,
    required Map<String, Object?> body,
    String? bearerToken,
    String method = 'POST',
    Map<String, String>? queryParameters,
  }) async {
    final base = Uri.parse(endpoint);
    if (base.scheme != 'https' || base.host.isEmpty || !base.hasPort) {
      throw const DesktopLinkProtocolException('Desktop endpoint must be HTTPS with an explicit port.');
    }
    final expectedPem = _normalizePem(pinnedCertificatePem);
    // No system roots: never send the token/text to a publicly trusted impostor.
    final securityContext = SecurityContext(withTrustedRoots: false)
      ..setTrustedCertificatesBytes(utf8.encode(pinnedCertificatePem));
    final client = HttpClient(context: securityContext)
      ..connectionTimeout = const Duration(seconds: 2);
    client.badCertificateCallback = (certificate, host, port) =>
        host == base.host && port == base.port && _normalizePem(certificate.pem) == expectedPem;
    try {
      final uri = base.replace(
        path: path,
        queryParameters: queryParameters,
        fragment: null,
      );
      final request = await client.openUrl(method, uri).timeout(const Duration(seconds: 3));
      request.followRedirects = false;
      request.headers.set(HttpHeaders.cacheControlHeader, 'no-store');
      if (bearerToken != null) {
        request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $bearerToken');
      }
      if (method != 'GET' && method != 'DELETE') {
        request.headers.contentType = ContentType.json;
        final bodyBytes = utf8.encode(jsonEncode(body));
        request.contentLength = bodyBytes.length;
        request.add(bodyBytes);
      }
      final response = await request.close().timeout(const Duration(seconds: 60));
      final certificate = response.certificate;
      if (certificate == null || _normalizePem(certificate.pem) != expectedPem) {
        throw HandshakeException('Desktop certificate pin did not match pairing data.');
      }
      final text = await response.transform(utf8.decoder).join()
          .timeout(const Duration(seconds: 30));
      final decoded = jsonDecode(text);
      if (decoded is! Map) {
        throw const DesktopLinkProtocolException('Desktop returned invalid JSON.');
      }
      final payload = Map<String, Object?>.from(decoded);
      if (response.statusCode != HttpStatus.ok) {
        final error = payload['error'] ?? 'http_${response.statusCode}';
        final message = payload['message'];
        final detail = message is String && message.isNotEmpty ? ' — $message' : '';
        throw DesktopLinkProtocolException('Desktop rejected request: $error$detail');
      }
      return payload;
    } finally {
      client.close(force: true);
    }
  }

  static bool _sameCredential(
    DesktopLinkCredential left,
    DesktopLinkCredential right,
  ) =>
      left.endpoint == right.endpoint &&
      left.mobileToken == right.mobileToken &&
      left.certificatePem == right.certificatePem &&
      left.detectionPackSha256 == right.detectionPackSha256 &&
      left.clientId == right.clientId &&
      left.clientName == right.clientName &&
      left.relayUrl == right.relayUrl &&
      left.relayRoomId == right.relayRoomId &&
      left.relayToken == right.relayToken &&
      left.remoteSecret == right.remoteSecret;

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
