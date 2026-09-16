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
  });

  final String endpoint;
  final String mobileToken;
  final String certificatePem;
  final String detectionPackSha256;
  final String clientId;
  final String clientName;

  Map<String, Object?> toJson() => {
        'endpoint': endpoint,
        'mobileToken': mobileToken,
        'certificatePem': certificatePem,
        'detectionPackSha256': detectionPackSha256,
        'clientId': clientId,
        'clientName': clientName,
      };

  factory DesktopLinkCredential.fromJson(Map<String, Object?> json) {
    String read(String key) {
      final value = json[key];
      if (value is! String || value.isEmpty) {
        throw FormatException('Desktop Link credential field $key is invalid.');
      }
      return value;
    }

    return DesktopLinkCredential(
      endpoint: read('endpoint'),
      mobileToken: read('mobileToken'),
      certificatePem: read('certificatePem'),
      detectionPackSha256: read('detectionPackSha256'),
      clientId: read('clientId'),
      clientName: read('clientName'),
    );
  }
}
