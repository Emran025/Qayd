import 'package:qayd/domain/exceptions/currency_mismatch_exception.dart';
import 'package:qayd/domain/exceptions/invalid_amount_exception.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Monetary amount stored in minor units (e.g. halalas) with fixed scale [fractionalDigits].
///
/// Every Money object carries a [CurrencyCode]. Currency is a classification
/// label — arithmetic is only valid between Money of the **same** currency.
/// Cross-currency arithmetic is a structural domain error.
final class Money implements Comparable<Money> {
  const Money._(this.minorUnits, this.currency);

  /// Number of fractional decimal places — delegated to [currency.fractionalDigits].
  int get fractionalDigits => currency.fractionalDigits;

  /// Zero balance for a specific currency (allowed for balance checks; not valid as a voucher line amount).
  static Money zero(CurrencyCode currency) => Money._(0, currency);

  final int minorUnits;

  /// The currency classification of this amount.
  final CurrencyCode currency;

  /// Strictly positive amount (voucher totals, ledger line amounts).
  factory Money.positiveAmount(int minorUnits, CurrencyCode currency) {
    if (minorUnits <= 0) {
      throw  InvalidAmountException(
        messageAr: AppStrings.theAmountMustBe,
        code: 'money_not_positive',
      );
    }
    return Money._(minorUnits, currency);
  }

  /// Non-negative amount (e.g. computed balances).
  factory Money.nonNegative(int minorUnits, CurrencyCode currency) {
    if (minorUnits < 0) {
      throw  InvalidAmountException(
        messageAr: AppStrings.theAmountCannotBe,
        code: 'money_negative',
      );
    }
    return Money._(minorUnits, currency);
  }

  /// Any amount (positive or negative). Used for balances and results of arithmetic.
  factory Money.fromMinorUnits(int minorUnits, CurrencyCode currency) {
    return Money._(minorUnits, currency);
  }

  bool get isZero => minorUnits == 0;
  bool get isNegative => minorUnits < 0;

  void _assertSameCurrency(Money other) {
    if (currency != other.currency) {
      throw CurrencyMismatchException(
        messageAr: AppStrings.itIsNotPossible,
        code: 'cross_currency_arithmetic',
        currencyA: currency.code,
        currencyB: other.currency.code,
      );
    }
  }

  @override
  int compareTo(Money other) {
    _assertSameCurrency(other);
    return minorUnits.compareTo(other.minorUnits);
  }

  Money operator +(Money other) {
    _assertSameCurrency(other);
    return Money._(minorUnits + other.minorUnits, currency);
  }

  Money operator -(Money other) {
    _assertSameCurrency(other);
    return Money._(minorUnits - other.minorUnits, currency);
  }

  Money operator -() {
    return Money._(-minorUnits, currency);
  }

  Money abs() {
    return Money._(minorUnits.abs(), currency);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Money &&
          other.minorUnits == minorUnits &&
          other.currency == currency;

  @override
  int get hashCode => Object.hash(minorUnits, currency);

  @override
  String toString() => 'Money($minorUnits minor ${currency.code})';
}
