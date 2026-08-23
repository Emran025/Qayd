import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/entities/voucher.dart';

/// Immutable accounting payload prepared for atomic persistence.
///
/// This object contains a voucher and its generated entries, but it does not
/// write to the database. A later transaction coordinator owns persistence.
final class PosAccountingPosting {
  const PosAccountingPosting({
    required this.sourceId,
    required this.voucher,
    required this.entries,
  });

  final String sourceId;
  final Voucher voucher;
  final List<LedgerEntry> entries;
}
