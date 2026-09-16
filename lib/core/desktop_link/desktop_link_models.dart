class DesktopLinkPairingBundle {
  const DesktopLinkPairingBundle({
    required this.endpoints,
    required this.pairingCode,
    required this.expiresAt,
    required this.certificatePem,
    required this.certificateSha256,
    required this.detectionPackSha256,
  });

  final List<String> endpoints;
  final String pairingCode;
  final DateTime expiresAt;
  final String certificatePem;
  final String certificateSha256;
  final String detectionPackSha256;

  factory DesktopLinkPairingBundle.fromJson(Map<String, Object?> json) {
    final rawEndpoints = json['endpoints'];
    if (rawEndpoints is! List || rawEndpoints.any((item) => item is! String)) {
      throw const FormatException('Desktop pairing endpoints are invalid.');
    }
    final code = json['pairing_code'];
    final expires = json['expires_at'];
    final certificatePem = json['certificate_pem'];
    final certificateSha256 = json['certificate_sha256'];
    final detectionPackSha256 = json['detection_pack_sha256'];
    if (code is! String ||
        expires is! num ||
        certificatePem is! String ||
        certificateSha256 is! String ||
        detectionPackSha256 is! String) {
      throw const FormatException('Desktop pairing bundle is incomplete.');
    }
    return DesktopLinkPairingBundle(
      endpoints: List.unmodifiable(rawEndpoints.cast<String>()),
      pairingCode: code,
      expiresAt: DateTime.fromMillisecondsSinceEpoch(
        (expires.toDouble() * 1000).round(),
        isUtc: true,
      ),
      certificatePem: certificatePem,
      certificateSha256: certificateSha256,
      detectionPackSha256: detectionPackSha256,
    );
  }
}

class DesktopLinkCredential {
  const DesktopLinkCredential({
    required this.endpoint,
    required this.mobileToken,
    required this.certificatePem,
    required this.detectionPackSha256,
    required this.clientId,
    required this.clientName,
    this.relayUrl = '',
    this.relayRoomId = '',
    this.relayToken = '',
    this.remoteSecret = '',
  });

  final String endpoint;
  final String mobileToken;
  final String certificatePem;
  final String detectionPackSha256;
  final String clientId;
  final String clientName;
  final String relayUrl;
  final String relayRoomId;
  final String relayToken;
  final String remoteSecret;

  bool get hasRemoteRelay =>
      relayUrl.isNotEmpty &&
      relayRoomId.isNotEmpty &&
      relayToken.isNotEmpty &&
      remoteSecret.isNotEmpty;

  Map<String, Object?> toJson() => {
        'endpoint': endpoint,
        'mobileToken': mobileToken,
        'certificatePem': certificatePem,
        'detectionPackSha256': detectionPackSha256,
        'clientId': clientId,
        'clientName': clientName,
        'relayUrl': relayUrl,
        'relayRoomId': relayRoomId,
        'relayToken': relayToken,
        'remoteSecret': remoteSecret,
      };

  DesktopLinkCredential copyWith({
    String? endpoint,
    String? mobileToken,
    String? certificatePem,
    String? detectionPackSha256,
    String? clientId,
    String? clientName,
    String? relayUrl,
    String? relayRoomId,
    String? relayToken,
    String? remoteSecret,
  }) =>
      DesktopLinkCredential(
        endpoint: endpoint ?? this.endpoint,
        mobileToken: mobileToken ?? this.mobileToken,
        certificatePem: certificatePem ?? this.certificatePem,
        detectionPackSha256: detectionPackSha256 ?? this.detectionPackSha256,
        clientId: clientId ?? this.clientId,
        clientName: clientName ?? this.clientName,
        relayUrl: relayUrl ?? this.relayUrl,
        relayRoomId: relayRoomId ?? this.relayRoomId,
        relayToken: relayToken ?? this.relayToken,
        remoteSecret: remoteSecret ?? this.remoteSecret,
      );

  DesktopLinkCredential withRemoteRelay(Map<String, Object?> payload) {
    final version = payload['version'];
    final url = payload['url'];
    final roomId = payload['room_id'];
    final token = payload['relay_token'];
    final secret = payload['remote_secret'];
    final cipher = payload['cipher'];
    final contentStorage = payload['content_storage'];
    if (version != 1 ||
        url is! String ||
        !url.startsWith('wss://') ||
        roomId is! String ||
        roomId.isEmpty ||
        token is! String ||
        token.isEmpty ||
        secret is! String ||
        secret.isEmpty ||
        cipher != 'AES-256-GCM' ||
        contentStorage != false) {
      throw const FormatException('Desktop remote Device Trust data is invalid.');
    }
    return copyWith(
      relayUrl: url,
      relayRoomId: roomId,
      relayToken: token,
      remoteSecret: secret,
    );
  }

  factory DesktopLinkCredential.fromJson(Map<String, Object?> json) {
    String read(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Desktop Link credential field $key is invalid.');
      }
      return value;
    }

    String optional(String key) {
      final value = json[key];
      return value is String ? value : '';
    }

    return DesktopLinkCredential(
      endpoint: read('endpoint'),
      mobileToken: read('mobileToken'),
      certificatePem: read('certificatePem'),
      detectionPackSha256: read('detectionPackSha256'),
      clientId: read('clientId'),
      clientName: read('clientName'),
      relayUrl: optional('relayUrl'),
      relayRoomId: optional('relayRoomId'),
      relayToken: optional('relayToken'),
      remoteSecret: optional('remoteSecret'),
    );
  }
}
