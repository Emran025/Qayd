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

  /// Atomically persists two linked vouchers as a tripartite transfer pair.
  Future<Result<void>> saveTripartitePair({
    required Voucher receiptVoucher,
    required Voucher paymentVoucher,
  });

  /// Atomically persists a tripartite pair along with their ledger entries.
  Future<Result<void>> saveTripartitePairWithLedgerEntries({
    required Voucher receiptVoucher,
    required List<LedgerEntry> receiptEntries,
    required Voucher paymentVoucher,
    required List<LedgerEntry> paymentEntries,
  });

  /// Fetches all vouchers sharing the given [transferGroupId].
  Future<Result<List<Voucher>>> getByTransferGroupId(String transferGroupId);

  // ── Threaded Financial Interactions (Protocol v1.3) ──────────────────────

  /// Fetches all vouchers that reference the given [originId] as their parent.
  /// Used for rendering thread counts and reply navigation.
  Future<Result<List<Voucher>>> getByOriginVoucherId(VoucherId originId);

  /// Searches for a reciprocal match in local drafts for inbound claim deduplication.
  /// Criteria: matching amount, currency, inverse type, counterparty == self, ±24h window.
  Future<Result<Voucher?>> findReciprocalMatch({
    required int amountMinor,
    required String currencyCode,
    required String counterpartyAccountId,
    required String type,
    required DateTime referenceDate,
  });
}
