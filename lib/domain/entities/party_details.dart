import 'package:qayd/domain/value_objects/account_id.dart';

/// Operational metadata for a counterparty linked to an account.
///
/// Extended for the Digital Signature Protocol to include:
/// - [email] for identity matching alongside phone.
/// - [currentPublicKeyHex] — the currently active public key.
/// - [publicKeyHistoryHex] — historical public keys for fallback verification.
/// - [serverAccountId] — optional server-side Chart of Accounts linkage.
class PartyDetails {
  const PartyDetails({
    required this.accountId,
    this.phoneNumber,
    this.email,
    this.whatsappNumber,
    this.bankAccountInfo,
    this.partyType,
    this.currentPublicKeyHex,
    this.publicKeyHistoryHex = const [],
    this.serverAccountId,
  });

  final AccountId accountId;
  final String? phoneNumber;
  final String? email;
  final String? whatsappNumber;
  final String? bankAccountInfo;
  final String? partyType;

  /// The counterparty's currently active Ed25519 public key (64 hex chars).
  final String? currentPublicKeyHex;

  /// Historical public keys ordered newest-first, for fallback verification.
  final List<String> publicKeyHistoryHex;

  /// Optional linkage to the server-side Chart of Accounts ID.
  final int? serverAccountId;

  /// All authorized keys: current + historical, for iterative verification.
  List<String> get allAuthorizedKeys => [
        if (currentPublicKeyHex != null) currentPublicKeyHex!,
        ...publicKeyHistoryHex,
      ];

  /// Whether this counterparty has any known public key.
  bool get hasPublicKey => currentPublicKeyHex != null;

  /// Returns a copy with updated public keys.
  PartyDetails updatePublicKeys({
    required String newCurrentKeyHex,
    List<String>? newHistoryHex,
  }) {
    // If the current key is changing, push old one to history.
    final updatedHistory = <String>[
      ...?newHistoryHex,
      if (currentPublicKeyHex != null &&
          currentPublicKeyHex != newCurrentKeyHex)
        currentPublicKeyHex!,
      ...publicKeyHistoryHex,
    ];
    // Deduplicate while preserving order.
    final seen = <String>{};
    final deduped = updatedHistory.where((k) => seen.add(k)).toList();

    return PartyDetails(
      accountId: accountId,
      phoneNumber: phoneNumber,
      email: email,
      whatsappNumber: whatsappNumber,
      bankAccountInfo: bankAccountInfo,
      partyType: partyType,
      currentPublicKeyHex: newCurrentKeyHex,
      publicKeyHistoryHex: deduped,
      serverAccountId: serverAccountId,
    );
  }

  /// Returns a copy with all fields optionally overridden.
  PartyDetails copyWith({
    String? phoneNumber,
    String? email,
    String? whatsappNumber,
    String? bankAccountInfo,
    String? partyType,
    String? currentPublicKeyHex,
    List<String>? publicKeyHistoryHex,
    int? serverAccountId,
  }) {
    return PartyDetails(
      accountId: accountId,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      email: email ?? this.email,
      whatsappNumber: whatsappNumber ?? this.whatsappNumber,
      bankAccountInfo: bankAccountInfo ?? this.bankAccountInfo,
      partyType: partyType ?? this.partyType,
      currentPublicKeyHex: currentPublicKeyHex ?? this.currentPublicKeyHex,
      publicKeyHistoryHex: publicKeyHistoryHex ?? this.publicKeyHistoryHex,
      serverAccountId: serverAccountId ?? this.serverAccountId,
    );
  }
}
