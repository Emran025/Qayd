/// Supplies the SQLCipher passphrase. Replace with Keystore/Keychain-backed
/// derivation (PBKDF2/Argon2) per `sqlite_secure_design.md` §3.2 for production.
abstract interface class DatabaseEncryptionKeyProvider {
  Future<String> obtainKey();
}

/// Development-only fixed key. Do not ship to production without replacing.
final class DevelopmentDatabaseEncryptionKeyProvider
    implements DatabaseEncryptionKeyProvider {
  const DevelopmentDatabaseEncryptionKeyProvider();

  @override
  Future<String> obtainKey() async => 'qayd_sqlcipher_dev_key_v1_change_me';
}
