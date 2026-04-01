import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pointycastle/export.dart' as pc;
import 'package:qayd/data/security/mnemonic_vault.dart';
import 'package:qayd/domain/value_objects/crypto_key_pair.dart';
import 'package:qayd/domain/value_objects/mnemonic_phrase.dart';

/// Persists the cryptographic identity to an AES-encrypted file alongside
/// [qayd_finance.db] so it survives app reinstallation on Android (where
/// the Keystore is tied to the app signing certificate and may be cleared).
///
/// Security model:
/// - AES-CBC with PKCS7 padding, key derived from a hardware-bound secret.
/// - Provides meaningful protection against casual file inspection.
/// - The hardware-derived key means the file is device-bound.
/// - Full-disk encryption on modern Android/iOS provides the outer layer.
final class IdentityFileStorage {
  IdentityFileStorage({required String hardwareId})
      : _hardwareId = hardwareId;

  final String _hardwareId;

  static const String _fileName = 'qayd_identity.dat';
  static const String _version = 'v1';

  // ── AES key derivation ───────────────────────────────────────────────────

  Uint8List get _aesKey {
    final raw = utf8.encode('${_hardwareId}_qayd_identity_key_$_version');
    return Uint8List.fromList(sha256.convert(raw).bytes);
  }

  Uint8List get _iv {
    final raw = utf8.encode('${_hardwareId}_qayd_identity_iv_$_version');
    return Uint8List.fromList(sha256.convert(raw).bytes.sublist(0, 16));
  }

  // ── AES-CBC encrypt / decrypt ────────────────────────────────────────────

  Uint8List _encrypt(Uint8List data) {
    final key = _aesKey;
    final iv = _iv;
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

  Uint8List _decrypt(Uint8List data) {
    final key = _aesKey;
    final iv = _iv;
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

  // ── File path ─────────────────────────────────────────────────────────────

  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Persists [mnemonic] and [keyPair] to the device file alongside the DB.
  Future<void> persist({
    required MnemonicPhrase mnemonic,
    required CryptoKeyPair keyPair,
  }) async {
    try {
      final payload = jsonEncode({
        'version': _version,
        'mnemonic': mnemonic.phrase,
        'public_key': keyPair.publicKeyHex,
        'private_key': keyPair.privateKeyHex,
      });
      final encrypted = _encrypt(Uint8List.fromList(utf8.encode(payload)));
      final file = await _file;
      await file.writeAsBytes(encrypted);
    } catch (_) {
      // Non-fatal: secure storage remains the primary source of truth.
    }
  }

  /// Returns true if an identity file exists on disk.
  Future<bool> hasStoredIdentity() async {
    try {
      final f = await _file;
      return f.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Reads from the file and writes to [vault] if the vault has no identity.
  ///
  /// Called during [InjectionContainer.init] to auto-restore after reinstall.
  Future<bool> restoreToVaultIfAvailable(MnemonicVault vault) async {
    try {
      final f = await _file;
      if (!f.existsSync()) return false;
      final encrypted = await f.readAsBytes();
      final decrypted = _decrypt(encrypted);
      final json = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      final mnemonicStr = json['mnemonic'] as String?;
      final pubHex = json['public_key'] as String?;
      final privHex = json['private_key'] as String?;
      if (mnemonicStr == null || pubHex == null || privHex == null) return false;
      final mnemonic = MnemonicPhrase.fromPhrase(mnemonicStr);
      final keyPair = CryptoKeyPair.fromHex(
        privateKeyHex: privHex,
        publicKeyHex: pubHex,
      );
      await vault.writeMnemonic(mnemonic);
      await vault.writeKeyPair(keyPair);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the stored identity file. Called by [PanicWipeService].
  Future<void> delete() async {
    try {
      final f = await _file;
      if (f.existsSync()) await f.delete();
    } catch (_) {}
  }
}
