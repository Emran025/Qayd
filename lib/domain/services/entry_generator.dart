import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/exceptions/invalid_state_transition_exception.dart';
import 'package:qayd/domain/value_objects/entry_id.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

/// Builds the two ledger lines for a confirmed receipt or payment voucher (shared [TransactionId]).
class EntryGenerator {
  const EntryGenerator();

  /// Produces a balanced debit/credit pair per `vouchers_and_ledgers.md` §5.
  ///
  /// [voucher] must already be [VoucherState.confirmed]. Caller supplies fresh ids and timestamps.
  /// Currency is inherited from the voucher.
  List<LedgerEntry> generateForConfirmedVoucher({
    required Voucher voucher,
    required TransactionId transactionId,
    required EntryId debitEntryId,
    required EntryId creditEntryId,
    required DateTime ledgerCreatedAt,
  }) {
    if (!voucher.state.isConfirmed) {
      throw const InvalidStateTransitionException(
        messageAr: 'لا يمكن إنشاء قيود لسند غير مؤكد.',
        code: 'entries_require_confirmed_voucher',
      );
    }

    final amount = voucher.amount;
    final currency = voucher.currency;
    final date = voucher.date;
    final voucherId = voucher.id;

    switch (voucher.type) {
      case VoucherType.receipt:
        return [
          LedgerEntry.create(
            id: debitEntryId,
            transactionId: transactionId,
            accountId: voucher.affectedAccountId,
            side: EntrySide.debit,
            amount: amount,
            currency: currency,
            voucherId: voucherId,
            date: date,
            createdAt: ledgerCreatedAt,
          ),
          LedgerEntry.create(
            id: creditEntryId,
            transactionId: transactionId,
            accountId: voucher.counterpartyId,
            side: EntrySide.credit,
            amount: amount,
            currency: currency,
            voucherId: voucherId,
            date: date,
            createdAt: ledgerCreatedAt,
          ),
        ];
      case VoucherType.payment:
        return [
          LedgerEntry.create(
            id: debitEntryId,
            transactionId: transactionId,
            accountId: voucher.counterpartyId,
            side: EntrySide.debit,
            amount: amount,
            currency: currency,
            voucherId: voucherId,
            date: date,
            createdAt: ledgerCreatedAt,
          ),
          LedgerEntry.create(
            id: creditEntryId,
            transactionId: transactionId,
            accountId: voucher.affectedAccountId,
            side: EntrySide.credit,
            amount: amount,
            currency: currency,
            voucherId: voucherId,
            date: date,
            createdAt: ledgerCreatedAt,
          ),
        ];
    }
  }
}
