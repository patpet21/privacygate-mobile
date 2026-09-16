import 'dart:convert';
import 'dart:io';

import 'desktop_connection.dart';
import 'protected_copy.dart';

class MobileLinkException implements Exception {
  const MobileLinkException(this.message);
  final String message;
  @override
  String toString() => message;
}

class PairingRequest {
  const PairingRequest(this.requestId);
  final String requestId;
}

class PairingStatus {
  const PairingStatus({required this.status, this.bearerToken});
  final String status;
  final String? bearerToken;
  bool get approved => status == 'approved' && bearerToken != null;
}

class DesktopPairingClient {
  DesktopPairingClient(this.bootstrap);

  final PairingBootstrap bootstrap;

  Future<PairingRequest> requestPairing({
    required String clientId,
    String clientName = 'PrivacyGate Mobile',
  }) async {
    if (bootstrap.isExpired) {
      throw const MobileLinkException('Pairing data expired. Create a fresh QR on Desktop.');
    }
    final response = await _requestJson(
      bootstrap: bootstrap,
      method: 'POST',
      path: '/v1/mobile/pair',
      body: {
        'pairing_code': bootstrap.pairingCode,
        'client_id': clientId,
        'client_name': clientName,
      },
    );
    final requestId = response['pairing_request_id'];
    if (requestId is! String || requestId.isEmpty) {
      throw const MobileLinkException('Desktop did not return a pairing request ID.');
    }
    return PairingRequest(requestId);
  }

  Future<PairingStatus> checkStatus(String requestId) async {
    final response = await _requestJson(
      bootstrap: bootstrap,
      method: 'GET',
      path: '/v1/mobile/pair/status?request_id=${Uri.encodeQueryComponent(requestId)}',
    );
    final status = response['pairing_status'];
    if (status is! String) {
      throw const MobileLinkException('Desktop returned an invalid pairing status.');
    }
    final token = response['mobile_token'];
    return PairingStatus(
      status: status,
      bearerToken: token is String && token.isNotEmpty ? token : null,
    );
  }
}

class MobileLinkClient {
  MobileLinkClient(this.connection);

  final DesktopConnection connection;

  Future<List<ProtectedCopyGrant>> listProtectedCopyGrants() async {
    final response = await _requestJson(
      connection: connection,
      method: 'GET',
      path: '/v1/mobile/library/grants',
    );
    if (response['automatic_sync'] != false) {
      throw const MobileLinkException('Desktop returned an unsafe automatic-sync contract.');
    }
    final grants = response['grants'];
    if (grants is! List) {
      throw const MobileLinkException('Desktop returned an invalid protected-copy list.');
    }
    return List<ProtectedCopyGrant>.unmodifiable(
      grants.map((item) {
        if (item is! Map<String, dynamic>) {
          throw const FormatException('Invalid protected-copy grant.');
        }
        return ProtectedCopyGrant.fromJson(item);
      }),
    );
  }

  Future<ProtectedCopyDocument> fetchProtectedCopy(String grantId) async {
    if (!RegExp(r'^[A-Za-z0-9_-]{12,128}$').hasMatch(grantId)) {
      throw const MobileLinkException('Invalid protected-copy grant ID.');
    }
    final response = await _requestJson(
      connection: connection,
      method: 'GET',
      path: '/v1/mobile/library/grants/${Uri.encodeComponent(grantId)}',
    );
    return ProtectedCopyDocument.fromJson(response);
  }
}

Future<Map<String, dynamic>> _requestJson({
  PairingBootstrap? bootstrap,
  DesktopConnection? connection,
  required String method,
  required String path,
  Map<String, dynamic>? body,
}) async {
  if ((bootstrap == null) == (connection == null)) {
    throw ArgumentError('Exactly one Desktop connection source is required.');
  }
  final endpoint = bootstrap?.endpoint ?? connection!.endpoint;
  final certificatePem = bootstrap?.certificatePem ?? connection!.certificatePem;
  final base = Uri.parse(endpoint);
  final parsedPath = Uri.parse(path);
  final uri = base.replace(path: parsedPath.path, query: parsedPath.query);
  final context = SecurityContext(withTrustedRoots: false);
  context.setTrustedCertificatesBytes(utf8.encode(certificatePem));
  final client = HttpClient(context: context)
    ..connectionTimeout = const Duration(seconds: 8)
    ..badCertificateCallback = (certificate, host, port) {
      return host == base.host && certificate.pem.trim() == certificatePem.trim();
    };

  try {
    final request = method == 'POST' ? await client.postUrl(uri) : await client.getUrl(uri);
    request.headers.set(HttpHeaders.acceptHeader, 'application/json');
    if (connection != null) {
      request.headers.set(HttpHeaders.authorizationHeader, 'Bearer ${connection.bearerToken}');
    }
    if (body != null) {
      request.headers.contentType = ContentType.json;
      request.write(jsonEncode(body));
    }
    final response = await request.close().timeout(const Duration(seconds: 12));
    final responseText = await utf8.decoder.bind(response).join();
    Map<String, dynamic> decoded = const {};
    if (responseText.isNotEmpty) {
      final value = jsonDecode(responseText);
      if (value is! Map<String, dynamic>) {
        throw const MobileLinkException('Desktop returned an invalid JSON response.');
      }
      decoded = value;
    }
    if (response.statusCode < 200 || response.statusCode >= 300) {
      final message = decoded['message'] ?? decoded['error'] ?? 'Desktop request failed.';
      throw MobileLinkException(message.toString());
    }
    return decoded;
  } on SocketException {
    throw const MobileLinkException('Desktop is unavailable on the local network.');
  } on HandshakeException {
    throw const MobileLinkException('Desktop TLS identity could not be verified.');
  } on FormatException catch (error) {
    throw MobileLinkException(error.message);
  } finally {
    client.close(force: true);
  }
}
