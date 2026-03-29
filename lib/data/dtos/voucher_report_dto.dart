/// Snapshot for voucher PDF generation (data → PDF engine boundary).
class VoucherReportDto {
  const VoucherReportDto({
    required this.voucherId,
    required this.typeCode,
    required this.stateCode,
    required this.dateIso,
    required this.amountMinorUnits,
    required this.counterpartyAccountId,
    required this.counterpartyName,
    required this.affectedAccountId,
    required this.affectedName,
    this.referenceNumber,
    this.description,
    this.notes,
    required this.createdAtIso,
    this.confirmedAtIso,
    this.settledAtIso,
  });

  final String voucherId;
  final String typeCode;
  final String stateCode;
  final String dateIso;
  final int amountMinorUnits;
  final String counterpartyAccountId;
  final String counterpartyName;
  final String affectedAccountId;
  final String affectedName;
  final String? referenceNumber;
  final String? description;
  final String? notes;
  final String createdAtIso;
  final String? confirmedAtIso;
  final String? settledAtIso;
}
