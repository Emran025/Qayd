/// Input DTO for creating a dual transfer (two standard vouchers through the fund).
class CreateDualTransferInput {
  const CreateDualTransferInput({
    required this.senderAccountId,
    required this.receiverAccountId,
    required this.fundAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.date,
    this.description,
    this.notes,
    this.confirm = false,
  });

  /// The external sender party (money debited from their account).
  final String senderAccountId;

  /// The external receiver party (money credited to their account).
  final String receiverAccountId;

  /// The fund/cashbox account (intermediary).
  final String fundAccountId;

  final int amountMinorUnits;
  final String currencyCode;
  final DateTime date;
  final String? description;
  final String? notes;

  /// If true, both vouchers are immediately confirmed (signed) and enqueued for sync.
  final bool confirm;
}
