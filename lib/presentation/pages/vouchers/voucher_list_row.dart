import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';

sealed class VoucherListRow {
  const VoucherListRow();
}

final class VoucherListPeriodDivider extends VoucherListRow {
  const VoucherListPeriodDivider({
    required this.label,
    required this.isClosed,
  });

  final String label;
  final bool isClosed;
}

final class VoucherListVoucherRow extends VoucherListRow {
  const VoucherListVoucherRow(this.dto);

  final VoucherSummaryDto dto;
}

/// Visual milestone row that marks a signed settlement checkpoint.
final class VoucherListSettlementRow extends VoucherListRow {
  const VoucherListSettlementRow({
    required this.label,
    this.currencyCode,
    this.balanceMinorUnits,
  });

  final String label;
  final String? currencyCode;
  final int? balanceMinorUnits;
}
