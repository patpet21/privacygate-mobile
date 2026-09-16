import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class PairingBootstrap {
  const PairingBootstrap({
    required this.endpoint,
    required this.pairingCode,
    required this.expiresAt,
    required this.certificatePem,
  });

  final String endpoint;
  final String pairingCode;
  final DateTime expiresAt;
  final String certificatePem;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAt.toUtc());

  factory PairingBootstrap.fromJsonText(String text) {
    final decoded = jsonDecode(text);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Pairing data must be a JSON object.');
    }
    if (decoded['version'] != 1) {
      throw const FormatException('Unsupported pairing version.');
    }
    final endpoints = decoded['endpoints'];
    if (endpoints is! List || endpoints.isEmpty || endpoints.first is! String) {
      throw const FormatException('Pairing data does not contain a Desktop endpoint.');
    }
    final endpoint = (endpoints.first as String).trim();
    final uri = Uri.tryParse(endpoint);
    if (uri == null || uri.scheme != 'https' || uri.host.isEmpty) {
      throw const FormatException('Desktop endpoint must use HTTPS.');
    }
    final code = decoded['pairing_code'];
    if (code is! String || !RegExp(r'^\d{8}$').hasMatch(code)) {
      throw const FormatException('Pairing code is invalid.');
    }
    final expiry = decoded['expires_at'];
    if (expiry is! num) {
      throw const FormatException('Pairing expiry is invalid.');
    }
    final certificate = decoded['certificate_pem'];
    if (certificate is! String || !certificate.contains('BEGIN CERTIFICATE')) {
      throw const FormatException('Desktop certificate is missing.');
    }
    return PairingBootstrap(
      endpoint: endpoint,
      pairingCode: code,
      expiresAt: DateTime.fromMillisecondsSinceEpoch((expiry * 1000).round(), isUtc: true),
      certificatePem: certificate,
    );
  }
}

class DesktopConnection {
  const DesktopConnection({
    required this.endpoint,
    required this.bearerToken,
    required this.certificatePem,
    required this.clientId,
  });

  final String endpoint;
  final String bearerToken;
  final String certificatePem;
  final String clientId;
}

class DesktopConnectionStore {
  DesktopConnectionStore({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  static const _endpointKey = 'privacygate.mobile.desktop.endpoint.v1';
  static const _tokenKey = 'privacygate.mobile.desktop.token.v1';
  static const _certificateKey = 'privacygate.mobile.desktop.certificate.v1';
  static const _clientIdKey = 'privacygate.mobile.device.id.v1';

  final FlutterSecureStorage _storage;

  Future<String> ensureClientId() async {
    final existing = await _storage.read(key: _clientIdKey);
    if (existing != null && RegExp(r'^[A-Za-z0-9._-]{8,128}$').hasMatch(existing)) {
      return existing;
    }
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    final id = 'mobile-${bytes.map((value) => value.toRadixString(16).padLeft(2, '0')).join()}';
    await _storage.write(key: _clientIdKey, value: id);
    return id;
  }

  Future<DesktopConnection?> load() async {
    final values = await Future.wait([
      _storage.read(key: _endpointKey),
      _storage.read(key: _tokenKey),
      _storage.read(key: _certificateKey),
      _storage.read(key: _clientIdKey),
    ]);
    if (values.any((value) => value == null || value!.isEmpty)) return null;
    return DesktopConnection(
      endpoint: values[0]!,
      bearerToken: values[1]!,
      certificatePem: values[2]!,
      clientId: values[3]!,
    );
  }

  Future<void> save({
    required PairingBootstrap bootstrap,
    required String bearerToken,
    required String clientId,
  }) async {
    if (bearerToken.isEmpty) throw ArgumentError('bearerToken cannot be empty');
    await _storage.write(key: _endpointKey, value: bootstrap.endpoint);
    await _storage.write(key: _tokenKey, value: bearerToken);
    await _storage.write(key: _certificateKey, value: bootstrap.certificatePem);
    await _storage.write(key: _clientIdKey, value: clientId);
  }

  Future<void> clearConnection() async {
    await _storage.delete(key: _endpointKey);
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _certificateKey);
  }
}
