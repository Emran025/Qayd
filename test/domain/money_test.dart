import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/domain/exceptions/currency_mismatch_exception.dart';
import 'package:qayd/domain/exceptions/invalid_amount_exception.dart';
import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/predefined_currencies.dart';

void main() {
  group('Money', () {
    final sar = PredefinedCurrencies.sar;
    final usd = PredefinedCurrencies.usd;

    test('positiveAmount accepts positive minor units', () {
      final m = Money.positiveAmount(100, sar);
      expect(m.minorUnits, 100);
      expect(m.currency, sar);
    });

    test('positiveAmount rejects zero and negative', () {
      expect(
        () => Money.positiveAmount(0, sar),
        throwsA(isA<InvalidAmountException>()),
      );
      expect(
        () => Money.positiveAmount(-1, sar),
        throwsA(isA<InvalidAmountException>()),
      );
    });

    test('nonNegative accepts zero', () {
      expect(Money.nonNegative(0, sar).isZero, true);
    });

    test('nonNegative rejects negative', () {
      expect(
        () => Money.nonNegative(-1, sar),
        throwsA(isA<InvalidAmountException>()),
      );
    });

    test('addition same currency', () {
      final a = Money.nonNegative(100, sar);
      final b = Money.nonNegative(50, sar);
      expect((a + b).minorUnits, 150);
    });

    test('addition mismatch throws', () {
      final a = Money.nonNegative(100, sar);
      final b = Money.nonNegative(50, usd);
      expect(() => a + b, throwsA(isA<CurrencyMismatchException>()));
    });

    test('subtraction enforces same currency and non-negative', () {
      final a = Money.nonNegative(100, sar);
      final b = Money.nonNegative(30, sar);
      expect((a - b).minorUnits, 70);
    });

    test('compareTo orders by minor units', () {
      expect(
        Money.positiveAmount(10, sar).compareTo(Money.positiveAmount(20, sar)),
        lessThan(0),
      );
    });

    test('equality uses minor units and currency', () {
      expect(Money.nonNegative(5, sar), Money.nonNegative(5, sar));
      expect(Money.nonNegative(5, sar) == Money.nonNegative(5, usd), false);
      expect(Money.nonNegative(5, sar) == Money.nonNegative(6, sar), false);
    });
  });
}
