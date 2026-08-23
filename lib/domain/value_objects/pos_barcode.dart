import 'package:qayd/domain/exceptions/invalid_pos_barcode_exception.dart';

/// Normalized product barcode used by camera and hardware scanner adapters.
final class PosBarcode {
  PosBarcode(String raw) : value = _normalize(raw);

  final String value;

  static String _normalize(String raw) {
    final normalized = raw.trim();
    if (normalized.isEmpty || normalized.length > 128) {
      throw InvalidPosBarcodeException();
    }
    if (normalized.contains(RegExp(r'[\r\n\t]'))) {
      throw InvalidPosBarcodeException();
    }
    return normalized;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is PosBarcode && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}
