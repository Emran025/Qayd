import 'dart:typed_data';

/// Immutable Ed25519 asymmetric key pair for signing and verification.
///
/// - [privateKey]: 32-byte seed (NEVER leaves the device or is transmitted).
/// - [publicKey]: 32-byte public key (registered on server for discovery).
///
/// Both are raw byte arrays. Hex encoding is handled at serialization boundaries.
final class CryptoKeyPair {
  const CryptoKeyPair({
    required this.privateKey,
    required this.publicKey,
  });

  /// 32-byte Ed25519 private key seed.
  final Uint8List privateKey;

  /// 32-byte Ed25519 public key.
  final Uint8List publicKey;

  /// Hex-encoded public key for display, QR, and API transmission.
  String get publicKeyHex =>
      publicKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Hex-encoded private key — use only for secure local storage.
  String get privateKeyHex =>
      privateKey.map((b) => b.toRadixString(16).padLeft(2, '0')).join();

  /// Reconstructs from hex-encoded strings.
  factory CryptoKeyPair.fromHex({
    required String privateKeyHex,
    required String publicKeyHex,
  }) {
    return CryptoKeyPair(
      privateKey: _hexToBytes(privateKeyHex),
      publicKey: _hexToBytes(publicKeyHex),
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
  String toString() => 'CryptoKeyPair(pub=${publicKeyHex.substring(0, 8)}…)';
}
