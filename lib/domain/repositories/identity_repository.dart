/// Domain contract for public key discovery via the governance API.
///
/// The server stores only public keys; private keys never leave the device.
abstract interface class IdentityRepository {
  /// Registers or rotates the user's public key on the server.
  ///
  /// [publicKeyHex] — hex-encoded Ed25519 public key (64 chars).
  /// Returns the server-assigned key generation number.
  Future<int> registerPublicKey({required String publicKeyHex});

  /// Looks up a user's public key by phone number.
  ///
  /// Returns `null` if no user with that phone number exists or if
  /// no public key has been registered.
  Future<PublicKeyLookupResult?> lookupByPhone({required String phone});

  /// Batch lookup of public keys by phone numbers.
  ///
  /// Returns a map of phone → result for each resolved phone number.
  Future<Map<String, PublicKeyLookupResult>> lookupBatch({
    required List<String> phones,
  });
}

/// Result of a public key lookup from the server.
final class PublicKeyLookupResult {
  const PublicKeyLookupResult({
    required this.phone,
    required this.publicKeyHex,
    required this.keyGeneration,
    required this.name,
  });

  final String phone;
  final String publicKeyHex;
  final int keyGeneration;
  final String name;
}
