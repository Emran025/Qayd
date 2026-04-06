/// Single chat "message" line in the Statement of Account conversation UI.
class AccountStatementChatMessageDto {
  const AccountStatementChatMessageDto({
    required this.voucherId,
    required this.dateIso,
    required this.direction,
    required this.typeCode,
    required this.voucherStateCode,
    required this.signatureStatusCode,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.currencySymbol,
    required this.currencyDigits,
    required this.description,
    required this.otherPartyId,
    required this.otherPartyName,
    this.runningBalanceMinorUnits = 0,
    this.referenceNumber,
  });

  final String voucherId;
  final String dateIso;

  /// `incoming` or `outgoing` relative to the selected "my account".
  final String direction;

  /// `receipt` or `payment`.
  final String typeCode;

  /// `draft` | `confirmed` | `settled`
  final String voucherStateCode;

  /// `underRequest` | `accepted` | `rejected` | `unverified`
  final String signatureStatusCode;

  final int amountMinorUnits;
  final String currencyCode;
  final String currencySymbol;
  final int currencyDigits;

  /// Voucher "description/notes" merged for chat display.
  final String description;

  final String otherPartyId;
  final String otherPartyName;

  /// Cumulative running balance (minor units) up to and including this message.
  /// Positive = counterparty owes user; Negative = user owes counterparty.
  final int runningBalanceMinorUnits;

  /// Voucher reference number if present.
  final String? referenceNumber;
}
