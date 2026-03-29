import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';

class ListVouchersOutput {
  const ListVouchersOutput({
    required this.vouchers,
    this.accountNamesById = const {},
  });

  final List<VoucherSummaryDto> vouchers;

  /// For filter chips (account id → display name).
  final Map<String, String> accountNamesById;
}
