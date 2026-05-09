import 'package:qayd/domain/value_objects/voucher_id.dart';

enum FiscalPeriodStatus { open, closing, closed }

/// Logical accounting period; when [status] is [FiscalPeriodStatus.closed],
/// [aggregateSnapshotHash] and signatures anchor balances for sync and reporting.
final class FiscalPeriod {
  const FiscalPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.closedAt,
    this.closingVoucherId,
    this.aggregateSnapshotHash,
    this.aggregateSignatureHex,
    this.signerPublicKeyHex,
  });

  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final FiscalPeriodStatus status;
  final DateTime? closedAt;
  final VoucherId? closingVoucherId;
  final String? aggregateSnapshotHash;
  final String? aggregateSignatureHex;
  final String? signerPublicKeyHex;

  bool containsCalendarDate(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    final s = DateTime(startDate.year, startDate.month, startDate.day);
    final e = DateTime(endDate.year, endDate.month, endDate.day);
    return !d.isBefore(s) && !d.isAfter(e);
  }

  bool overlapsRange(DateTime start, DateTime end) {
    final a0 = DateTime(start.year, start.month, start.day);
    final a1 = DateTime(end.year, end.month, end.day);
    final b0 = DateTime(startDate.year, startDate.month, startDate.day);
    final b1 = DateTime(endDate.year, endDate.month, endDate.day);
    return !a1.isBefore(b0) && !a0.isAfter(b1);
  }
}
