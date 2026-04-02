import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:pointycastle/export.dart' as pc;

/// Utility for AES-256-CBC file encryption/decryption.
///
/// Used to encrypt backup files and identity data at rest.
/// The encryption key is derived from a passphrase + salt using SHA-256.
final class FileEncryptor {
  const FileEncryptor();

  /// Encrypts [data] using AES-256-CBC with PKCS7 padding.
  ///
  /// [key] must be exactly 32 bytes (256-bit).
  /// [iv] must be exactly 16 bytes.
  Uint8List encrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        true,
        pc.PaddedBlockCipherParameters(
          pc.ParametersWithIV(pc.KeyParameter(key), iv),
          null,
        ),
      );
    return cipher.process(data);
  }

  /// Decrypts [data] using AES-256-CBC with PKCS7 padding.
  Uint8List decrypt(Uint8List data, Uint8List key, Uint8List iv) {
    final cipher = pc.PaddedBlockCipher('AES/CBC/PKCS7')
      ..init(
        false,
        pc.PaddedBlockCipherParameters(
          pc.ParametersWithIV(pc.KeyParameter(key), iv),
          null,
        ),
      );
    return cipher.process(data);
  }

  /// Derives a 32-byte key and 16-byte IV from a passphrase and salt.
  ({Uint8List key, Uint8List iv}) deriveKeyAndIv(
    String passphrase,
    String salt,
  ) {
    final rawKey = utf8.encode('${passphrase}_${salt}_key');
    final rawIv = utf8.encode('${passphrase}_${salt}_iv');
    return (
      key: Uint8List.fromList(sha256.convert(rawKey).bytes),
      iv: Uint8List.fromList(sha256.convert(rawIv).bytes.sublist(0, 16)),
    );
  }

  /// Encrypts a file in-place or to a destination.
  Future<void> encryptFile(
    String sourcePath,
    String destPath,
    Uint8List key,
    Uint8List iv,
  ) async {
    final data = await File(sourcePath).readAsBytes();
    final encrypted = encrypt(Uint8List.fromList(data), key, iv);
    await File(destPath).writeAsBytes(encrypted);
  }

  /// Decrypts a file in-place or to a destination.
  Future<void> decryptFile(
    String sourcePath,
    String destPath,
    Uint8List key,
    Uint8List iv,
  ) async {
    final data = await File(sourcePath).readAsBytes();
    final decrypted = decrypt(Uint8List.fromList(data), key, iv);
    await File(destPath).writeAsBytes(decrypted);
  }
}
