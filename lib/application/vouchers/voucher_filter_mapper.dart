import 'package:qayd/application/vouchers/dtos/advanced_filter_input.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/voucher_query_filter.dart';

abstract final class VoucherFilterMapper {
  static VoucherQueryFilter? toDomain(AdvancedFilterInput? input) {
    if (input == null || !input.hasAny) {
      return null;
    }
    DateRange? dateRange;
    if (input.fromDate != null || input.toDate != null) {
      final from = input.fromDate ?? input.toDate!;
      final to = input.toDate ?? input.fromDate!;
      dateRange = DateRange(
        start: DateTime(from.year, from.month, from.day),
        end: DateTime(to.year, to.month, to.day, 23, 59, 59, 999),
      );
    }
    return VoucherQueryFilter(
      state: input.state,
      type: input.type,
      dateRange: dateRange,
      counterpartyId: _idOrNull(input.counterpartyAccountId),
      affectedAccountId: _idOrNull(input.affectedAccountId),
      costCenterId: input.costCenterId,
      involvedRootAccountId: _idOrNull(input.involvedRootAccountId),
      involvedCounterRootAccountId: _idOrNull(input.involvedCounterRootAccountId),
      isInternalOnly: input.isInternalOnly,
    );
  }

  static AccountId? _idOrNull(String? raw) {
    final t = raw?.trim();
    if (t == null || t.isEmpty) {
      return null;
    }
    return AccountId(t);
  }
}
