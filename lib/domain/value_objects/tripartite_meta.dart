import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/tripartite_role.dart';

/// Immutable metadata linking a voucher to its tripartite transfer group.
///
/// Present only on vouchers created through the intermediary transfer flow.
/// Links the receipt (A→C) and payment (C→B) via a shared [transferGroupId].
final class TripartiteMeta {
  const TripartiteMeta({
    required this.transferGroupId,
    required this.role,
    required this.linkedPartyId,
    this.mediatorAccountId,
    this.feeAmount,
    this.isContingent = false,
  });

  /// UUID shared between the receipt and payment vouchers in this transfer.
  final String transferGroupId;

  /// Which leg of the transfer this voucher represents.
  final TripartiteRole role;

  /// The counterpart party in the chain:
  /// - On the receipt (A→C): stores B's account ID (final beneficiary).
  /// - On the payment (C→B): stores A's account ID (original source).
  final AccountId linkedPartyId;

  /// The mediator (A) account ID who is facilitating this transfer.
  final AccountId? mediatorAccountId;

  /// The fee amount (if any) taken by the mediator for this transfer.
  final Money? feeAmount;

  /// When `true`, this voucher is locked (cannot be shared/signed) until
  /// its parent voucher in the group transitions to confirmed/verified.
  final bool isContingent;

  /// Returns a copy with [isContingent] set to `false` (released).
  TripartiteMeta release() => TripartiteMeta(
        transferGroupId: transferGroupId,
        role: role,
        linkedPartyId: linkedPartyId,
        mediatorAccountId: mediatorAccountId,
        feeAmount: feeAmount,
        isContingent: false,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TripartiteMeta &&
          transferGroupId == other.transferGroupId &&
          role == other.role &&
          linkedPartyId == other.linkedPartyId &&
          mediatorAccountId == other.mediatorAccountId &&
          feeAmount == other.feeAmount &&
          isContingent == other.isContingent;

  @override
  int get hashCode => Object.hash(
        transferGroupId,
        role,
        linkedPartyId,
        mediatorAccountId,
        feeAmount,
        isContingent,
      );

  @override
  String toString() =>
      'TripartiteMeta(group=$transferGroupId, role=${role.name}, linked=${linkedPartyId.value}, mediator=${mediatorAccountId?.value}, fee=$feeAmount, contingent=$isContingent)';
}
