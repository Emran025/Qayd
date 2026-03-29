import 'package:qayd/domain/exceptions/invalid_amount_exception.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Immutable ledger line; corrections are done via reversal entries, never mutation.
final class LedgerEntry {
  const LedgerEntry._({
    required this.id,
    required this.transactionId,
    required this.accountId,
    required this.side,
    required this.amount,
    required this.currency,
    required this.voucherId,
    required this.date,
    required this.createdAt,
  });

  final EntryId id;
  final TransactionId transactionId;
  final AccountId accountId;
  final EntrySide side;
  final Money amount;
  final CurrencyCode currency;
  final VoucherId voucherId;
  final DateTime date;
  final DateTime createdAt;

  factory LedgerEntry.create({
    required EntryId id,
    required TransactionId transactionId,
    required AccountId accountId,
    required EntrySide side,
    required Money amount,
    required CurrencyCode currency,
    required VoucherId voucherId,
    required DateTime date,
    required DateTime createdAt,
  }) {
    if (amount.isZero) {
      throw const InvalidAmountException(
        messageAr: 'مبلغ القيد يجب أن يكون أكبر من صفر.',
        code: 'ledger_amount_zero',
      );
    }
    return LedgerEntry._(
      id: id,
      transactionId: transactionId,
      accountId: accountId,
      side: side,
      amount: amount,
      currency: currency,
      voucherId: voucherId,
      date: date,
      createdAt: createdAt,
    );
  }
}
