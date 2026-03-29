import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_query_filter.dart';

/// Persistence port for vouchers and coordinated ledger writes.
abstract interface class VoucherRepository {
  Future<Result<Voucher>> getById(VoucherId id);

  Future<Result<List<Voucher>>> getAll({
    VoucherQueryFilter? filter,
    int? limit,
    int? offset,
  });

  Future<Result<List<Voucher>>> getByCounterparty(
    AccountId counterpartyId, {
    DateRange? dateRange,
  });

  Future<Result<void>> save(Voucher voucher);

  /// Deletes a voucher only when it is still a draft (enforced in data layer).
  Future<Result<void>> deleteDraft(VoucherId id);

  Future<Result<List<Voucher>>> search({
    required String queryText,
    VoucherQueryFilter? filter,
  });

  Future<Result<int>> count({VoucherQueryFilter? filter});

  /// Single atomic transaction: persist [voucher] and [ledgerEntries] together
  /// (e.g. on confirmation with generated lines).
  Future<Result<void>> saveWithLedgerEntries({
    required Voucher voucher,
    required List<LedgerEntry> ledgerEntries,
  });
}
