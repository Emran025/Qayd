import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';

class TripartiteTransferSummaryDto {
  const TripartiteTransferSummaryDto({
    required this.transferGroupId,
    required this.dateIso,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.currencyNameAr,
    required this.sourceName,
    required this.destinationName,
    required this.affectedName,
    this.receiptVoucher,
    this.paymentVoucher,
  });

  final String transferGroupId;
  final String dateIso;
  final int amountMinorUnits;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;
  final String currencyNameAr;
  
  final String sourceName; // A
  final String destinationName; // B
  final String affectedName; // Our cashbox

  final VoucherSummaryDto? receiptVoucher;
  final VoucherSummaryDto? paymentVoucher;
}
