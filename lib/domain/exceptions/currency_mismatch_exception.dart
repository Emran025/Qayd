/// Thrown when code attempts arithmetic between two different currencies.
///
/// Cross-currency arithmetic is a structural error, equivalent to
/// violating the accounting equation. Currency is a classification label,
/// not a convertible quantity.
class CurrencyMismatchException implements Exception {
  const CurrencyMismatchException({
    required this.messageAr,
    this.code,
    this.currencyA,
    this.currencyB,
  });

  final String messageAr;
  final String? code;
  final String? currencyA;
  final String? currencyB;

  @override
  String toString() =>
      'CurrencyMismatchException: $messageAr ($currencyA ≠ $currencyB)';
}
