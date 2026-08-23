import 'package:qayd/domain/value_objects/money.dart';
import 'package:qayd/domain/value_objects/pos_quantity.dart';

/// Exact integer arithmetic for quantity-scaled money values.
abstract final class PosMoneyMath {
  static int scaleFactor(int scale) {
    var factor = 1;
    for (var i = 0; i < scale; i++) {
      factor *= 10;
    }
    return factor;
  }

  static Money multiply(PosQuantity quantity, Money unitPrice) {
    final divisor = scaleFactor(quantity.scale);
    final product = quantity.scaledUnits * unitPrice.minorUnits;
    final quotient = product ~/ divisor;
    final remainder = product % divisor;
    final rounded = quotient + (remainder * 2 >= divisor ? 1 : 0);
    return Money.fromMinorUnits(rounded, unitPrice.currency);
  }
}
