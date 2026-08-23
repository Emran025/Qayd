import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/domain/exceptions/invalid_pos_quantity_exception.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';

void main() {
  group('PosQuantity', () {
    test('whole quantity defaults to scale zero', () {
      final quantity = PosQuantity.whole(3);

      expect(quantity.scaledUnits, 3);
      expect(quantity.scale, 0);
      expect(quantity.toExactString(), '3');
    });

    test('positive quantity rejects zero', () {
      expect(
        () => PosQuantity.positive(0),
        throwsA(isA<InvalidPosQuantityException>()),
      );
    });

    test('quantity rejects negative values', () {
      expect(
        () => PosQuantity.whole(-1),
        throwsA(isA<InvalidPosQuantityException>()),
      );
    });

    test('quantity rejects unsupported scale', () {
      expect(
        () => PosQuantity.fromScaled(1, scale: PosQuantity.maxScale + 1),
        throwsA(isA<InvalidPosQuantityException>()),
      );
    });

    test('adds quantities with the same scale exactly', () {
      final first = PosQuantity.fromScaled(1250, scale: 3);
      final second = PosQuantity.fromScaled(750, scale: 3);

      final total = first + second;

      expect(total.scaledUnits, 2000);
      expect(total.scale, 3);
      expect(total.toExactString(), '2');
    });

    test('rejects arithmetic across different scales', () {
      final whole = PosQuantity.whole(2);
      final fractional = PosQuantity.fromScaled(2000, scale: 3);

      expect(
        () => whole + fractional,
        throwsA(isA<InvalidPosQuantityException>()),
      );
    });

    test('rejects subtraction that would become negative', () {
      expect(
        () => PosQuantity.whole(1) - PosQuantity.whole(2),
        throwsA(isA<InvalidPosQuantityException>()),
      );
    });

    test('multiplies using integer arithmetic', () {
      final quantity = PosQuantity.fromScaled(125, scale: 2);

      final total = quantity.multipliedBy(4);

      expect(total.scaledUnits, 500);
      expect(total.toExactString(), '5');
    });

    test('formats fractional units without trailing zeroes', () {
      expect(
        PosQuantity.fromScaled(1250, scale: 3).toExactString(),
        '1.25',
      );
      expect(
        PosQuantity.fromScaled(1001, scale: 3).toExactString(),
        '1.001',
      );
      expect(
        PosQuantity.fromScaled(5, scale: 3).toExactString(),
        '0.005',
      );
    });

    test('equality includes scale and scaled units', () {
      expect(
        PosQuantity.fromScaled(1000, scale: 3),
        PosQuantity.fromScaled(1000, scale: 3),
      );
      expect(
        PosQuantity.fromScaled(1, scale: 0) ==
            PosQuantity.fromScaled(1, scale: 3),
        isFalse,
      );
    });
  });
}
