import 'package:qayd/domain/value_objects/voucher_type.dart';

/// Lightweight summary of a voucher attached to a cost center.
/// Used for the integrated activity feed — avoids loading the full entity graph.
final class CenterVoucherSummary {
  const CenterVoucherSummary({
    required this.id,
    required this.type,
    required this.amountMinor,
    required this.currencyCode,
    this.description,
    required this.date,
    this.counterpartyName,
    this.dimensionIds = const [],
  });

  final String id;
  final VoucherType type;
  final int amountMinor;
  final String currencyCode;
  final String? description;
  final DateTime date;
  final String? counterpartyName;

  /// Dimension IDs this voucher is tagged with under this cost center.
  /// Used for contextual filtering when a donut segment is tapped.
  final List<String> dimensionIds;
}
