import 'package:qayd/domain/value_objects/sync_privacy_policy.dart';

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

  /// Looks up a user's public key by email.
  Future<PublicKeyLookupResult?> lookupByEmail({required String email});

  /// Batch lookup of public keys by phone numbers.
  ///
  /// Returns a map of phone → result for each resolved phone number.
  Future<Map<String, PublicKeyLookupResult>> lookupBatch({
    required List<String> phones,
  });

  /// Protocol §4 — Reverse lookup: discover a user's identity by public key.
  ///
  /// Used when a device receives a voucher with a public key but no
  /// phone/email, to discover the key owner via the server.
  Future<PublicKeyLookupResult?> reverseLookupByPublicKey({
    required String publicKeyHex,
  });

  /// Updates the user's profile on the server.
  ///
  /// [name], [phone], [email], [whatsappNumber] are optional fields to update.
  /// [avatarPath], [logoPath] are local file paths to images for upload.
  Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? phone,
    String? email,
    String? whatsappNumber,
    String? avatarPath,
    String? logoPath,
  });

  // ── Sync Privacy Policy Management ──────────────────────────────────────

  /// Fetches the user's current sync privacy policy and access list.
  Future<SyncPrivacyPolicy> getSyncPolicy();

  /// Updates the sync privacy policy mode.
  Future<void> updateSyncPolicy(SyncPolicyMode mode);

  /// Adds a user to the sync access list by phone.
  Future<SyncAccessEntry> addToSyncAccessList({
    required String phone,
    required String listType,
  });

  /// Removes an entry from the sync access list.
  Future<void> removeFromSyncAccessList({required int entryId});

  /// Soft-deletes the user's account from the server.
  Future<void> deleteAccount();
}

/// Result of a public key lookup from the server.
final class PublicKeyLookupResult {
  const PublicKeyLookupResult({
    required this.phone,
    this.email,
    this.whatsappNumber,
    this.publicKeyHex,
    this.previousPublicKeysHex = const [],
    this.keyGeneration,
    required this.name,
    this.syncBlocked = false,
    this.isRegistered = true,
    this.serverId,
  });

  final String phone;
  final String? email;
  final String? whatsappNumber;

  /// The most recent (active) public key.
  final String? publicKeyHex;

  /// History of rotated public keys for this identity.
  final List<String> previousPublicKeysHex;

  final int? keyGeneration;
  final String name;

  /// Whether the target user has restricted sync access to the requester.
  final bool syncBlocked;

  /// Whether the user has an account on the platform.
  final bool isRegistered;

  /// Numeric server-side user ID (when returned by server — used as primary routing hint).
  /// This is the fastest routing path: avoids phone/key lookup on the server.
  final int? serverId;

  /// All keys authorized to sign for this identity.
  List<String> get allAuthorizedKeys => [
        if (publicKeyHex != null) publicKeyHex!,
        ...previousPublicKeysHex
      ];
}

