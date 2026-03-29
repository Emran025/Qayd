import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Persists optional app lock PIN (salted SHA-256) and lock/biometric flags.
final class AppPinStorage {
  AppPinStorage({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kSalt = 'qayd_pin_salt_v1';
  static const _kHash = 'qayd_pin_hash_v1';
  static const _kLockEnabled = 'qayd_lock_enabled';
  static const _kBiometricEnabled = 'qayd_biometric_enabled';

  Future<bool> hasPinConfigured() async {
    final h = await _storage.read(key: _kHash);
    return h != null && h.isNotEmpty;
  }

  Future<bool> isLockEnabled() async {
    return (await _storage.read(key: _kLockEnabled)) == 'true';
  }

  Future<void> setLockEnabled(bool value) async {
    await _storage.write(
      key: _kLockEnabled,
      value: value ? 'true' : 'false',
    );
  }

  Future<bool> isBiometricEnabled() async {
    return (await _storage.read(key: _kBiometricEnabled)) == 'true';
  }

  Future<void> setBiometricEnabled(bool value) async {
    await _storage.write(
      key: _kBiometricEnabled,
      value: value ? 'true' : 'false',
    );
  }

  Future<void> setPin(String pin) async {
    final salt = _randomSalt();
    final hash = _hashPin(pin, salt);
    await _storage.write(key: _kSalt, value: salt);
    await _storage.write(key: _kHash, value: hash);
  }

  Future<void> clearPinAndLock() async {
    await _storage.delete(key: _kSalt);
    await _storage.delete(key: _kHash);
    await setLockEnabled(false);
    await setBiometricEnabled(false);
  }

  Future<bool> verifyPin(String pin) async {
    final salt = await _storage.read(key: _kSalt);
    final expected = await _storage.read(key: _kHash);
    if (salt == null || expected == null) return false;
    return _hashPin(pin, salt) == expected;
  }

  String _randomSalt() {
    final bytes = List<int>.generate(16, (_) => Random.secure().nextInt(256));
    return base64UrlEncode(bytes);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt::$pin');
    return sha256.convert(bytes).toString();
  }
}
