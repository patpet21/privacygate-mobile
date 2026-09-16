import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cryptography/cryptography.dart';

import 'desktop_link_models.dart';

class DesktopRemoteRelayException implements Exception {
  const DesktopRemoteRelayException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DesktopRemoteRelayClient {
  const DesktopRemoteRelayClient();

  static const _maxFrameBytes = 2500000;

  Future<Map<String, Object?>> requestJson({
    required DesktopLinkCredential credential,
    required String method,
    required String path,
    required Map<String, Object?> body,
    Map<String, String>? queryParameters,
  }) async {
    if (!credential.hasRemoteRelay) {
      throw const DesktopRemoteRelayException(
        'Remote Device Trust has not been provisioned for this pairing yet.',
      );
    }

    final base = Uri.parse(credential.relayUrl);
    if (base.scheme != 'wss' || base.host.isEmpty) {
      throw const DesktopRemoteRelayException('Remote relay URL is invalid.');
    }
    final room = Uri.encodeComponent(credential.relayRoomId);
    final basePath = base.path.endsWith('/')
        ? base.path.substring(0, base.path.length - 1)
        : base.path;
    final relayUri = base.replace(
      path: '$basePath/$room',
      queryParameters: {
        'role': 'mobile',
        'token': credential.relayToken,
      },
      fragment: null,
    );

    final targetUri = Uri(
      path: path,
      queryParameters: queryParameters == null || queryParameters.isEmpty
          ? null
          : queryParameters,
    );
    final requestId = _randomId();
    final clearPayload = <String, Object?>{
      'method': method.toUpperCase(),
      'target': targetUri.toString(),
      'bearer_token': credential.mobileToken,
      'body': body,
    };
    final frame = await _encrypt(
      requestId,
      clearPayload,
      credential: credential,
      direction: 'mobile_to_desktop',
    );

    WebSocket? socket;
    try {
      socket = await WebSocket.connect(
        relayUri.toString(),
        compression: CompressionOptions.compressionOff,
      ).timeout(const Duration(seconds: 6));
      socket.add(frame);

      final response = await _waitForResponse(
        socket,
        requestId: requestId,
        credential: credential,
      ).timeout(const Duration(seconds: 35));
      return response;
    } on SocketException {
      throw const DesktopRemoteRelayException(
        'Remote Device Trust relay is unreachable.',
      );
    } on TimeoutException {
      throw const DesktopRemoteRelayException(
        'Remote Desktop did not respond in time.',
      );
    } on WebSocketException catch (error) {
      throw DesktopRemoteRelayException('Remote Device Trust failed: ${error.message}');
    } finally {
      await socket?.close();
    }
  }

  Future<Map<String, Object?>> _waitForResponse(
    WebSocket socket, {
    required String requestId,
    required DesktopLinkCredential credential,
  }) async {
    await for (final event in socket) {
      if (event is! String || utf8.encode(event).length > _maxFrameBytes) continue;
      Map<String, Object?>? decoded;
      try {
        final raw = jsonDecode(event);
        if (raw is Map) decoded = Map<String, Object?>.from(raw);
      } on FormatException {
        continue;
      }
      if (decoded == null) continue;

      final type = decoded['type'];
      if (type == 'peer_offline') {
        throw const DesktopRemoteRelayException(
          'Desktop is paired but currently offline.',
        );
      }
      if (type == 'relay_ready' || type == 'peer_online' || type == 'pong') {
        continue;
      }
      if (decoded['v'] != 1 || decoded['id'] != requestId) continue;

      final clear = await _decrypt(
        decoded,
        requestId: requestId,
        credential: credential,
        direction: 'desktop_to_mobile',
      );
      final status = clear['status'];
      final rawBody = clear['body'];
      if (status is! int || rawBody is! Map) {
        throw const DesktopRemoteRelayException(
          'Remote Desktop returned an invalid response.',
        );
      }
      final responseBody = Map<String, Object?>.from(rawBody);
      if (status != HttpStatus.ok) {
        final error = responseBody['error'] ?? 'http_$status';
        final message = responseBody['message'];
        final suffix = message is String && message.isNotEmpty ? ' — $message' : '';
        throw DesktopRemoteRelayException('Desktop rejected request: $error$suffix');
      }
      return responseBody;
    }
    throw const DesktopRemoteRelayException('Remote Desktop connection closed.');
  }

  Future<String> _encrypt(
    String requestId,
    Map<String, Object?> payload, {
    required DesktopLinkCredential credential,
    required String direction,
  }) async {
    final algorithm = AesGcm.with256bits();
    final keyBytes = _decodeSecret(credential.remoteSecret);
    if (keyBytes.length != 32) {
      throw const DesktopRemoteRelayException('Remote Device Trust key is invalid.');
    }
    final nonce = algorithm.newNonce();
    final secretBox = await algorithm.encrypt(
      utf8.encode(jsonEncode(payload)),
      secretKey: SecretKey(keyBytes),
      nonce: nonce,
      aad: _aad(credential.relayRoomId, direction, requestId),
    );
    final combined = <int>[...secretBox.cipherText, ...secretBox.mac.bytes];
    return jsonEncode({
      'v': 1,
      'id': requestId,
      'nonce': _b64url(nonce),
      'ciphertext': _b64url(combined),
    });
  }

  Future<Map<String, Object?>> _decrypt(
    Map<String, Object?> frame, {
    required String requestId,
    required DesktopLinkCredential credential,
    required String direction,
  }) async {
    final nonceRaw = frame['nonce'];
    final cipherRaw = frame['ciphertext'];
    if (nonceRaw is! String || cipherRaw is! String) {
      throw const DesktopRemoteRelayException('Encrypted relay frame is invalid.');
    }
    final nonce = _b64urlDecode(nonceRaw);
    final combined = _b64urlDecode(cipherRaw);
    if (nonce.length != 12 || combined.length < 17) {
      throw const DesktopRemoteRelayException('Encrypted relay frame is malformed.');
    }
    final keyBytes = _decodeSecret(credential.remoteSecret);
    if (keyBytes.length != 32) {
      throw const DesktopRemoteRelayException('Remote Device Trust key is invalid.');
    }
    final tagStart = combined.length - 16;
    try {
      final clear = await AesGcm.with256bits().decrypt(
        SecretBox(
          combined.sublist(0, tagStart),
          nonce: nonce,
          mac: Mac(combined.sublist(tagStart)),
        ),
        secretKey: SecretKey(keyBytes),
        aad: _aad(credential.relayRoomId, direction, requestId),
      );
      final decoded = jsonDecode(utf8.decode(clear));
      if (decoded is! Map) {
        throw const DesktopRemoteRelayException('Remote Desktop response is invalid.');
      }
      return Map<String, Object?>.from(decoded);
    } on SecretBoxAuthenticationError {
      throw const DesktopRemoteRelayException(
        'Remote Device Trust authentication failed. Re-pair this device.',
      );
    }
  }

  static List<int> _aad(String roomId, String direction, String requestId) => utf8.encode(
        'privacygate-device-trust-remote-v1\n$roomId\n$direction\n$requestId',
      );

  static String _randomId() {
    final random = Random.secure();
    final bytes = List<int>.generate(18, (_) => random.nextInt(256));
    return _b64url(bytes);
  }

  static List<int> _decodeSecret(String value) => _b64urlDecode(value);

  static String _b64url(List<int> bytes) =>
      base64UrlEncode(bytes).replaceAll('=', '');

  static List<int> _b64urlDecode(String value) {
    final paddingLength = (4 - value.length % 4) % 4;
    final padding = List<String>.filled(paddingLength, '=').join();
    return base64Url.decode('$value$padding');
  }
}
