class CredentialBootstrapPayload {
  const CredentialBootstrapPayload({
    required this.version,
    required this.nonce,
    required this.mnemonic,
    required this.jwt,
    required this.issuedAtIso,
    required this.expiresAtIso,
    this.licenseData,
    this.deviceCertificate,
  });

  final int version;
  final String nonce;
  final String mnemonic;
  final String jwt;
  final String issuedAtIso;
  final String expiresAtIso;
  final Map<String, dynamic>? licenseData;
  final String? deviceCertificate;

  Map<String, dynamic> toMap() {
    return {
      'v': version,
      'nonce': nonce,
      'mnemonic': mnemonic,
      'jwt': jwt,
      'issued_at': issuedAtIso,
      'expires_at': expiresAtIso,
      if (licenseData != null) 'license_data': licenseData,
      if (deviceCertificate != null) 'device_certificate': deviceCertificate,
    };
  }

  factory CredentialBootstrapPayload.fromMap(Map<String, dynamic> map) {
    return CredentialBootstrapPayload(
      version: (map['v'] as num?)?.toInt() ?? 1,
      nonce: map['nonce'] as String? ?? '',
      mnemonic: map['mnemonic'] as String? ?? '',
      jwt: map['jwt'] as String? ?? '',
      issuedAtIso: map['issued_at'] as String? ?? '',
      expiresAtIso: map['expires_at'] as String? ?? '',
      licenseData: map['license_data'] is Map
          ? Map<String, dynamic>.from(map['license_data'] as Map)
          : null,
      deviceCertificate: map['device_certificate'] as String?,
    );
  }
}
