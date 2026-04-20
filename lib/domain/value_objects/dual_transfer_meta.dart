import 'package:qayd/domain/value_objects/account_id.dart';

/// Role of a voucher within a dual transfer group.
///
/// - [senderDebit]: Money flows from sender's account → fund (cashbox).
/// - [receiverCredit]: Money flows from fund (cashbox) → receiver's account.
enum DualTransferRole {
  senderDebit,
  receiverCredit;

  /// DB column value: snake_case string.
  String get columnValue => switch (this) {
        DualTransferRole.senderDebit => 'sender_debit',
        DualTransferRole.receiverCredit => 'receiver_credit',
      };

  /// Parses from DB column value; returns null for unrecognised strings.
  static DualTransferRole? fromColumnValue(String? raw) => switch (raw) {
        'sender_debit' => DualTransferRole.senderDebit,
        'receiver_credit' => DualTransferRole.receiverCredit,
        _ => null,
      };
}

/// Immutable metadata linking a voucher to its dual transfer group.
///
/// Unlike [TripartiteMeta], the fund (cashbox) IS affected in dual transfers.
/// Each dual transfer creates two standard vouchers:
/// 1. Receipt: sender → fund (debit from sender's account)
/// 2. Payment: fund → receiver (credit to receiver's account)
final class DualTransferMeta {
  const DualTransferMeta({
    required this.dualGroupId,
    required this.role,
    required this.linkedPartyId,
    required this.fundAccountId,
  });

  /// UUID shared between the two vouchers in this dual transfer.
  final String dualGroupId;

  /// Which leg of the transfer this voucher represents.
  final DualTransferRole role;

  /// The other external party in the transfer:
  /// - On the sender debit leg: stores the receiver's account ID.
  /// - On the receiver credit leg: stores the sender's account ID.
  final AccountId linkedPartyId;

  /// The fund (cashbox) account that is the intermediary.
  final AccountId fundAccountId;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DualTransferMeta &&
          dualGroupId == other.dualGroupId &&
          role == other.role &&
          linkedPartyId == other.linkedPartyId &&
          fundAccountId == other.fundAccountId;

  @override
  int get hashCode => Object.hash(
        dualGroupId,
        role,
        linkedPartyId,
        fundAccountId,
      );

  @override
  String toString() =>
      'DualTransferMeta(group=$dualGroupId, role=${role.name}, linked=${linkedPartyId.value}, fund=${fundAccountId.value})';
}
