import 'package:qayd/data/models/ledger_entry_model.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

final class LedgerEntryMapper {
  static LedgerEntryModel toModel(LedgerEntry entry) {
    return LedgerEntryModel(
      id: entry.id.value,
      transactionId: entry.transactionId.value,
      accountId: entry.accountId.value,
      side: entry.side.name,
      amountMinor: entry.amount.minorUnits,
      currencyCode: entry.currency.code,
      voucherId: entry.voucherId.value,
      dateIso: entry.date.toIso8601String(),
      createdAtIso: entry.createdAt.toIso8601String(),
    );
  }

  static LedgerEntry toEntity(LedgerEntryModel model, CurrencyCode currency) {
    return LedgerEntry.create(
      id: EntryId(model.id),
      transactionId: TransactionId(model.transactionId),
      accountId: AccountId(model.accountId),
      side: EntrySide.values.byName(model.side),
      amount: Money.positiveAmount(model.amountMinor, currency),
      currency: currency,
      voucherId: VoucherId(model.voucherId),
      date: DateTime.parse(model.dateIso),
      createdAt: DateTime.parse(model.createdAtIso),
    );
  }
}
