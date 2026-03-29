import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Persistence port for immutable ledger lines.
abstract interface class LedgerRepository {
  Future<Result<void>> createEntries(List<LedgerEntry> entries);

  Future<Result<List<LedgerEntry>>> getEntriesForAccount(
    AccountId accountId, {
    DateRange? dateRange,
  });

  Future<Result<List<LedgerEntry>>> getEntriesForTransaction(
    TransactionId transactionId,
  );

  Future<Result<List<LedgerEntry>>> getEntriesForVoucher(VoucherId voucherId);

  Future<Result<List<LedgerEntry>>> getAllEntries({DateRange? dateRange});
}
