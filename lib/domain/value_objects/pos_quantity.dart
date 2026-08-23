import 'package:qayd/domain/exceptions/invalid_pos_quantity_exception.dart';

/// Exact non-negative POS quantity stored as an integer at a fixed scale.
///
/// A scale of zero represents whole units. A scale of three, for example,
/// represents thousandths: `1250` means `1.250` units. No floating-point
/// arithmetic is used anywhere in this value object.
final class PosQuantity implements Comparable<PosQuantity> {
  const PosQuantity._({required this.scaledUnits, required this.scale});

  static const int minScale = 0;
  static const int maxScale = 6;

  final int scaledUnits;
  final int scale;

  factory PosQuantity.whole(int units) {
    return PosQuantity.fromScaled(units, scale: 0);
  }

  factory PosQuantity.positive(int scaledUnits, {int scale = 0}) {
    return PosQuantity.fromScaled(
      scaledUnits,
      scale: scale,
      allowZero: false,
    );
  }

  factory PosQuantity.fromScaled(
    int scaledUnits, {
    required int scale,
    bool allowZero = true,
  }) {
    if (scale < minScale || scale > maxScale) {
      throw InvalidPosQuantityException.invalidScale();
    }
    if (scaledUnits < 0) {
      throw InvalidPosQuantityException.negative();
    }
    if (!allowZero && scaledUnits == 0) {
      throw InvalidPosQuantityException.notPositive();
    }
    return PosQuantity._(scaledUnits: scaledUnits, scale: scale);
  }

  bool get isZero => scaledUnits == 0;
  bool get isPositive => scaledUnits > 0;

  PosQuantity operator +(PosQuantity other) {
    _assertSameScale(other);
    return PosQuantity._(
      scaledUnits: scaledUnits + other.scaledUnits,
      scale: scale,
    );
  }

  PosQuantity operator -(PosQuantity other) {
    _assertSameScale(other);
    final result = scaledUnits - other.scaledUnits;
    if (result < 0) {
      throw InvalidPosQuantityException.resultNegative();
    }
    return PosQuantity._(scaledUnits: result, scale: scale);
  }

  PosQuantity multipliedBy(int multiplier) {
    if (multiplier < 0) {
      throw InvalidPosQuantityException.negative();
    }
    return PosQuantity._(
      scaledUnits: scaledUnits * multiplier,
      scale: scale,
    );
  }

  String toExactString() {
    if (scale == 0) return scaledUnits.toString();

    final digits = scaledUnits.toString().padLeft(scale + 1, '0');
    final splitAt = digits.length - scale;
    final integerPart = digits.substring(0, splitAt);
    final fractionalPart = digits.substring(splitAt);
    final trimmedFraction = fractionalPart.replaceAll(RegExp(r'0+$'), '');
    return trimmedFraction.isEmpty ? integerPart : '$integerPart.$trimmedFraction';
  }

  void _assertSameScale(PosQuantity other) {
    if (scale != other.scale) {
      throw InvalidPosQuantityException.scaleMismatch();
    }
  }

  @override
  int compareTo(PosQuantity other) {
    _assertSameScale(other);
    return scaledUnits.compareTo(other.scaledUnits);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PosQuantity &&
            other.scaledUnits == scaledUnits &&
            other.scale == scale;
  }

  @override
  int get hashCode => Object.hash(scaledUnits, scale);

  @override
  String toString() => 'PosQuantity($scaledUnits/$scale)';
}
