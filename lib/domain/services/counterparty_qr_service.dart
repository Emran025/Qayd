import 'dart:convert';

/// Handles QR Code generation and parsing for counterparty account
/// import/export as specified in Protocol §3.
///
/// Key protocol requirements:
/// - Export: Merges user account info into a QR Code.
/// - Import: Populates fields; user confirms, can modify name.
/// - Immutable data: Email and Phone Number cannot be modified on import.
/// - Cryptographic Payload: Public Key List is strictly read-only.
class CounterpartyQrService {
  const CounterpartyQrService();

  /// Generates a QR code payload containing the user's account information.
  ///
  /// The payload includes:
  /// - Name, Phone, Email (identity fields)
  /// - Current public key + key history (cryptographic payload)
  /// - Server account ID (for Chart of Accounts linkage)
  String generateAccountQr({
    required String name,
    required String phone,
    required String email,
    required String currentPublicKeyHex,
    List<String> publicKeyHistoryHex = const [],
    int? serverAccountId,
  }) {
    final map = <String, dynamic>{
      'v': 1,
      'type': 'QAYD_ACCOUNT',
      'name': name,
      'phone': phone,
      'email': email,
      'current_pk': currentPublicKeyHex,
      if (publicKeyHistoryHex.isNotEmpty) 'pk_history': publicKeyHistoryHex,
      if (serverAccountId != null) 'server_id': serverAccountId,
      'ts': DateTime.now().toIso8601String(),
    };
    final jsonStr = json.encode(map);
    return base64.encode(utf8.encode(jsonStr));
  }

  /// Parses a counterparty QR code and returns the extracted fields.
  ///
  /// Returns `null` if the data is invalid or not a Qayd account QR.
  ///
  /// Per Protocol §3:
  /// - `name` is modifiable by the importing user (superficial detail).
  /// - `phone`, `email` are immutable (core identifiers).
  /// - `currentPublicKeyHex` and `publicKeyHistoryHex` are strictly read-only.
  CounterpartyQrData? parseAccountQr(String data) {
    try {
      final decoded = utf8.decode(base64.decode(data));
      final map = json.decode(decoded) as Map<String, dynamic>;

      // Validate this is a Qayd account QR.
      if (map['type'] != 'QAYD_ACCOUNT') return null;

      final version = map['v'] as int? ?? 1;
      if (version < 1) return null;

      final phone = map['phone'] as String?;
      final email = map['email'] as String?;
      final currentPk = map['current_pk'] as String?;

      // At minimum, phone or email must be present for identity matching.
      if (phone == null && email == null) return null;

      final historyRaw = map['pk_history'] as List<dynamic>? ?? [];
      final history = historyRaw.map((e) => e as String).toList();

      return CounterpartyQrData(
        version: version,
        name: map['name'] as String? ?? '',
        phone: phone ?? '',
        email: email ?? '',
        currentPublicKeyHex: currentPk,
        publicKeyHistoryHex: history,
        serverAccountId: map['server_id'] as int?,
      );
    } catch (_) {
      return null;
    }
  }
}

/// Parsed result from a counterparty account QR code.
///
/// Field mutability per Protocol §3:
/// - [name]: Modifiable (superficial detail).
/// - [phone], [email]: Immutable (core identifiers).
/// - [currentPublicKeyHex], [publicKeyHistoryHex]: Strictly read-only.
class CounterpartyQrData {
  const CounterpartyQrData({
    required this.version,
    required this.name,
    required this.phone,
    required this.email,
    this.currentPublicKeyHex,
    this.publicKeyHistoryHex = const [],
    this.serverAccountId,
  });

  final int version;

  /// Modifiable by the importing user.
  final String name;

  /// Core identifier — IMMUTABLE on import.
  final String phone;

  /// Core identifier — IMMUTABLE on import.
  final String email;

  /// The current active public key — STRICTLY READ-ONLY.
  final String? currentPublicKeyHex;

  /// Historical public keys — STRICTLY READ-ONLY.
  final List<String> publicKeyHistoryHex;

  /// Server-side Chart of Accounts ID, if known.
  final int? serverAccountId;

  /// Whether this QR contains cryptographic keys.
  bool get hasPublicKey => currentPublicKeyHex != null;

  /// All authorized keys (current + historical).
  List<String> get allKeys => [
        if (currentPublicKeyHex != null) currentPublicKeyHex!,
        ...publicKeyHistoryHex,
      ];
}
