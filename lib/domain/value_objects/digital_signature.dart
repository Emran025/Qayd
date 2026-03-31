import 'dart:typed_data';

/// Cryptographic Ed25519 signature over a receipt payload.
///
/// Contains the raw signature bytes, the signer's public key, and the
/// hash of the canonical payload that was signed.
final class DigitalSignature {
  const DigitalSignature({
    required this.signatureBytes,
    required this.signerPublicKey,
    required this.payloadHash,
  });

  /// 64-byte Ed25519 signature.
  final Uint8List signatureBytes;

  /// 32-byte public key of the signer.
  final Uint8List signerPublicKey;

  /// SHA-256 hash of the canonical payload that was signed.
  final Uint8List payloadHash;

  /// Hex-encoded signature (128 hex chars).
  String get signatureHex =>
      signatureBytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Hex-encoded signer public key (64 hex chars).
  String get signerPublicKeyHex =>
      signerPublicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Hex-encoded payload hash.
  String get payloadHashHex =>
      payloadHash.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Reconstructs from hex-encoded strings.
  factory DigitalSignature.fromHex({
    required String signatureHex,
    required String signerPublicKeyHex,
    required String payloadHashHex,
  }) {
    return DigitalSignature(
      signatureBytes: _hexToBytes(signatureHex),
      signerPublicKey: _hexToBytes(signerPublicKeyHex),
      payloadHash: _hexToBytes(payloadHashHex),
    );
  }

  static Uint8List _hexToBytes(String hex) {
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < hex.length; i += 2) {
      result[i ~/ 2] = int.parse(hex.substring(i, i + 2), radix: 16);
    }
    return result;
  }

  @override
  String toString() =>
      'DigitalSignature(sig=${signatureHex.substring(0, 16)}…, signer=${signerPublicKeyHex.substring(0, 8)}…)';
}
