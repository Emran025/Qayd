import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/voucher_state.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';

/// Domain-level filter for listing vouchers (no storage details).
final class VoucherQueryFilter {
  const VoucherQueryFilter({
    this.state,
    this.dateRange,
    this.counterpartyId,
    this.affectedAccountId,
    this.type,
    this.excludeTripartite,
    this.onlyTripartite,
  });

  final VoucherState? state;
  final DateRange? dateRange;
  final AccountId? counterpartyId;
  final AccountId? affectedAccountId;
  final VoucherType? type;
  final bool? excludeTripartite;
  final bool? onlyTripartite;

  bool get isEmpty =>
      state == null &&
      dateRange == null &&
      counterpartyId == null &&
      affectedAccountId == null &&
      type == null &&
      excludeTripartite == null &&
      onlyTripartite == null;
}
