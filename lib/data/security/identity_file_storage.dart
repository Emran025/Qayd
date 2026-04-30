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
///
/// The identity is persisted to TWO locations:
/// 1. App documents directory — primary location (may be deleted on uninstall).
/// 2. External app storage — secondary location (survives uninstall on Android).
class IdentityFileStorage {
  IdentityFileStorage({required String hardwareId}) : _hardwareId = hardwareId;

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

  // ── File paths ────────────────────────────────────────────────────────────

  /// Primary path: app documents directory.
  Future<File> get _file async {
    final dir = await getApplicationDocumentsDirectory();
    return File(p.join(dir.path, _fileName));
  }

  /// Secondary path: external storage (survives uninstall on Android).
  /// Falls back to documents directory on iOS / non-Android platforms.
  Future<File> get _externalFile async {
    Directory? extDir;
    if (Platform.isAndroid) {
      extDir = await getExternalStorageDirectory();
    }
    final baseDir = extDir ?? await getApplicationDocumentsDirectory();
    return File(p.join(baseDir.path, _fileName));
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Persists [mnemonic] and [keyPair] to BOTH internal and external storage.
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

      // Write to primary (app documents).
      final file = await _file;
      await file.writeAsBytes(encrypted);

      // Write to secondary (external storage, survives uninstall).
      try {
        final extFile = await _externalFile;
        if (extFile.path != file.path) {
          await extFile.writeAsBytes(encrypted);
        }
      } catch (_) {
        // External storage not available — non-fatal.
      }
    } catch (_) {
      // Non-fatal: secure storage remains the primary source of truth.
    }
  }

  /// Returns true if an identity file exists on disk (checks both locations).
  Future<bool> hasStoredIdentity() async {
    try {
      final f = await _file;
      if (f.existsSync()) return true;
      // Fallback: check external storage.
      final ef = await _externalFile;
      return ef.existsSync();
    } catch (_) {
      return false;
    }
  }

  /// Reads from the file and writes to [vault] if the vault has no identity.
  ///
  /// Tries primary file first, then falls back to external file.
  /// Called during [InjectionContainer.init] to auto-restore after reinstall.
  Future<bool> restoreToVaultIfAvailable(MnemonicVault vault) async {
    // Try primary location first.
    final restored = await _tryRestoreFromFile(await _file, vault);
    if (restored) return true;

    // Fallback: try external storage location.
    try {
      final extFile = await _externalFile;
      return await _tryRestoreFromFile(extFile, vault);
    } catch (_) {
      return false;
    }
  }

  /// Attempts to restore identity from a specific file.
  Future<bool> _tryRestoreFromFile(File f, MnemonicVault vault) async {
    try {
      if (!f.existsSync()) return false;
      final encrypted = await f.readAsBytes();
      final decrypted = _decrypt(encrypted);
      final json = jsonDecode(utf8.decode(decrypted)) as Map<String, dynamic>;
      final mnemonicStr = json['mnemonic'] as String?;
      final pubHex = json['public_key'] as String?;
      final privHex = json['private_key'] as String?;
      if (mnemonicStr == null || pubHex == null || privHex == null) {
        return false;
      }
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

  /// Deletes the stored identity file from both locations. Called by [PanicWipeService].
  Future<void> delete() async {
    try {
      final f = await _file;
      if (f.existsSync()) await f.delete();
    } catch (_) {}
    try {
      final ef = await _externalFile;
      if (ef.existsSync()) await ef.delete();
    } catch (_) {}
  }
}
