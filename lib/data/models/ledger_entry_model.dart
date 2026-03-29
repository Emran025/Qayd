/// SQLite projection for [ledger_entries] (v6 schema — includes currency_code).
final class LedgerEntryModel {
  const LedgerEntryModel({
    required this.id,
    required this.transactionId,
    required this.accountId,
    required this.side,
    required this.amountMinor,
    required this.currencyCode,
    required this.voucherId,
    required this.dateIso,
    required this.createdAtIso,
  });

  final String id;
  final String transactionId;
  final String accountId;
  final String side;
  final int amountMinor;
  final String currencyCode;
  final String voucherId;
  final String dateIso;
  final String createdAtIso;

  Map<String, Object?> toMap() => {
        'id': id,
        'transaction_id': transactionId,
        'account_id': accountId,
        'side': side,
        'amount_minor': amountMinor,
        'currency_code': currencyCode,
        'voucher_id': voucherId,
        'date': dateIso,
        'created_at': createdAtIso,
      };

  factory LedgerEntryModel.fromMap(Map<String, Object?> map) {
    return LedgerEntryModel(
      id: map['id']! as String,
      transactionId: map['transaction_id']! as String,
      accountId: map['account_id']! as String,
      side: map['side']! as String,
      amountMinor: map['amount_minor']! as int,
      currencyCode: map['currency_code']! as String,
      voucherId: map['voucher_id']! as String,
      dateIso: map['date']! as String,
      createdAtIso: map['created_at']! as String,
    );
  }
}
