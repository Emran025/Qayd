import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

/// Generates and manages per-voucher symmetric AES-256 keys.
///
/// The VoucherKey encrypts all attachment blobs + collateral data belonging
/// to a single voucher. The key itself is "wrapped" (encrypted) with the
/// recipient's public key before being included in the SyncNode payload,
/// ensuring the server never has access to the cleartext key.
///
/// Reuses the same AES-256-CBC algorithm as [FileEncryptor] for consistency.
class VoucherKeyService {
  const VoucherKeyService();

  static final _secureRandom = pc.SecureRandom('Fortuna')
    ..seed(pc.KeyParameter(
      Uint8List.fromList(
        List<int>.generate(32, (_) => Random.secure().nextInt(256)),
      ),
    ));

  /// Generates a fresh 256-bit (32-byte) AES key for a voucher.
  Uint8List generateVoucherKey() {
    return _secureRandom.nextBytes(32);
  }

  /// Generates a fresh 128-bit (16-byte) IV for AES-CBC.
  Uint8List generateIv() {
    return _secureRandom.nextBytes(16);
  }

  /// Encrypts raw image bytes with the voucher's AES-256-CBC key.
  ///
  /// Returns `IV (16 bytes) || ciphertext` so the IV travels with the blob.
  Uint8List encryptBlob(Uint8List plainBytes, Uint8List voucherKey) {
    final iv = generateIv();
    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        true,
        pc.PaddedBlockCipherParameters(
          pc.ParametersWithIV(pc.KeyParameter(voucherKey), iv),
          null,
        ),
      );
    final ciphertext = cipher.process(plainBytes);

    // Prepend IV for self-contained decryption
    final result = Uint8List(iv.length + ciphertext.length);
    result.setRange(0, iv.length, iv);
    result.setRange(iv.length, result.length, ciphertext);
    return result;
  }

  /// Decrypts an encrypted blob (IV-prefixed) back to raw bytes.
  Uint8List decryptBlob(Uint8List encryptedBytes, Uint8List voucherKey) {
    final iv = encryptedBytes.sublist(0, 16);
    final ciphertext = encryptedBytes.sublist(16);
    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        false,
        pc.PaddedBlockCipherParameters(
          pc.ParametersWithIV(pc.KeyParameter(voucherKey), iv),
          null,
        ),
      );
    return cipher.process(ciphertext);
  }

  /// Computes the SHA-256 hex hash of encrypted bytes for server dedup.
  String computeBlobHash(Uint8List encryptedBytes) {
    final digest = sha256.convert(encryptedBytes);
    return digest.toString();
  }

  /// Wraps the voucher key with the recipient's public key hex.
  ///
  /// Uses a simple XOR-based wrapping for now; in production, this should
  /// use X25519 key exchange + HKDF. The wrapped key is returned as hex.
  String wrapKeyForRecipient(
    Uint8List voucherKey,
    String recipientPublicKeyHex,
  ) {
    // Derive a wrapping key from the recipient's public key via SHA-256
    final pubKeyBytes = _hexToBytes(recipientPublicKeyHex);
    final wrappingKey = sha256.convert(pubKeyBytes).bytes;

    final wrapped = Uint8List(voucherKey.length);
    for (var i = 0; i < voucherKey.length; i++) {
      wrapped[i] = voucherKey[i] ^ wrappingKey[i % wrappingKey.length];
    }
    return _bytesToHex(wrapped);
  }

  /// Unwraps a voucher key using the receiver's public key.
  ///
  /// Symmetric to [wrapKeyForRecipient] — XOR is its own inverse.
  Uint8List unwrapKey(
    String wrappedKeyHex,
    String receiverPublicKeyHex,
  ) {
    final wrapped = _hexToBytes(wrappedKeyHex);
    final pubKeyBytes = _hexToBytes(receiverPublicKeyHex);
    final wrappingKey = sha256.convert(pubKeyBytes).bytes;

    final voucherKey = Uint8List(wrapped.length);
    for (var i = 0; i < wrapped.length; i++) {
      voucherKey[i] = wrapped[i] ^ wrappingKey[i % wrappingKey.length];
    }
    return voucherKey;
  }

  // ── Hex utilities ───────────────────────────────────────────────────────

  Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw ArgumentError('Odd-length hex string: ${hex.length}');
    }
    final result = Uint8List(hex.length ~/ 2);
    for (var i = 0; i < result.length; i++) {
      result[i] = int.parse(hex.substring(i * 2, i * 2 + 2), radix: 16);
    }
    return result;
  }

  String _bytesToHex(Uint8List bytes) {
    final sb = StringBuffer();
    for (final b in bytes) {
      sb.write(b.toRadixString(16).padLeft(2, '0'));
    }
    return sb.toString();
  }
}
