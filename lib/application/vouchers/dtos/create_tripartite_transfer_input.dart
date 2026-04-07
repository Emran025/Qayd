/// Input for creating a tripartite intermediary transfer (A → Me → B).
class CreateTripartiteTransferInput {
  const CreateTripartiteTransferInput({
    required this.sourceAccountId,
    required this.destinationAccountId,
    required this.affectedAccountId,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.date,
    this.description,
    this.notes,
  });

  /// Account ID of the source party (A) — money received FROM.
  final String sourceAccountId;

  /// Account ID of the destination party (B) — money paid TO.
  final String destinationAccountId;

  /// The mediator's own account (C) — usually the default cash/liquid account.
  final String affectedAccountId;

  /// Amount in minor units (identical for both receipt and payment).
  final int amountMinorUnits;

  /// ISO 4217 currency code.
  final String currencyCode;

  /// Date of the transfer.
  final DateTime date;

  /// Optional description for both vouchers.
  final String? description;

  /// Optional notes.
  final String? notes;

  CreateTripartiteTransferInput copyWith({
    String? sourceAccountId,
    String? destinationAccountId,
    String? affectedAccountId,
    int? amountMinorUnits,
    String? currencyCode,
    DateTime? date,
    String? description,
    String? notes,
  }) {
    return CreateTripartiteTransferInput(
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      affectedAccountId: affectedAccountId ?? this.affectedAccountId,
      amountMinorUnits: amountMinorUnits ?? this.amountMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      date: date ?? this.date,
      description: description ?? this.description,
      notes: notes ?? this.notes,
    );
  }
}
