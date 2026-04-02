import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages storage and retrieval of encryption keys from platform secure storage.
///
/// Wraps [FlutterSecureStorage] to provide a focused API for key management.
final class KeyManager {
  KeyManager({FlutterSecureStorage? storage})
      : _storage = storage ?? const FlutterSecureStorage();

  final FlutterSecureStorage _storage;

  static const _kDbEncryptionKey = 'qayd_db_derived_key_v2';

  /// Reads the stored DB encryption key, or null if not yet derived.
  Future<String?> readDbEncryptionKey() =>
      _storage.read(key: _kDbEncryptionKey);

  /// Writes the DB encryption key.
  Future<void> writeDbEncryptionKey(String key) =>
      _storage.write(key: _kDbEncryptionKey, value: key);

  /// Deletes the stored DB encryption key (used during panic wipe).
  Future<void> deleteDbEncryptionKey() =>
      _storage.delete(key: _kDbEncryptionKey);

  /// Reads a named key from secure storage.
  Future<String?> readKey(String name) => _storage.read(key: name);

  /// Writes a named key to secure storage.
  Future<void> writeKey(String name, String value) =>
      _storage.write(key: name, value: value);
}
