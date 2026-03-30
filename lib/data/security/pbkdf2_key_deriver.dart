import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';

/// Derives a cryptographic key from a password + salt using PBKDF2-HMAC-SHA256.
///
/// Spec: PBKDF2(Salt: ServerIssuedSalt + HardwareID, Iterations: 1000)
abstract final class Pbkdf2KeyDeriver {
  static const int _iterations = 1000;
  static const int _keyLength = 32; // 256-bit

  /// Derives a hex-encoded 256-bit key.
  ///
  /// [password] — the secret material (hardware ID or PIN).
  /// [salt] — combined salt bytes (server salt ++ hardware ID bytes).
  static String derive({
    required String password,
    required String salt,
    int iterations = _iterations,
    int keyLengthBytes = _keyLength,
  }) {
    final passwordBytes = utf8.encode(password);
    final saltBytes = utf8.encode(salt);

    final derived = _pbkdf2HmacSha256(
      passwordBytes,
      saltBytes,
      iterations,
      keyLengthBytes,
    );

    return derived.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// PBKDF2 with HMAC-SHA256. Single-block variant (keyLength ≤ 32 bytes).
  static Uint8List _pbkdf2HmacSha256(
    List<int> password,
    List<int> salt,
    int iterations,
    int keyLengthBytes,
  ) {
    final hmacSha256 = Hmac(sha256, password);

    // U1 = PRF(Password, Salt || INT(1))
    final saltWithBlock = Uint8List(salt.length + 4);
    saltWithBlock.setAll(0, salt);
    saltWithBlock[salt.length] = 0;
    saltWithBlock[salt.length + 1] = 0;
    saltWithBlock[salt.length + 2] = 0;
    saltWithBlock[salt.length + 3] = 1;

    var u = Uint8List.fromList(hmacSha256.convert(saltWithBlock).bytes);
    final t = Uint8List.fromList(u);

    for (var i = 1; i < iterations; i++) {
      u = Uint8List.fromList(hmacSha256.convert(u).bytes);
      for (var j = 0; j < t.length; j++) {
        t[j] ^= u[j];
      }
    }

    return Uint8List.sublistView(t, 0, keyLengthBytes);
  }
}
