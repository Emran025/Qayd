/// Strongly typed identifier for a voucher document.
final class VoucherId {
  const VoucherId._(this.value);

  final String value;

  factory VoucherId(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'VoucherId must be non-empty');
    }
    return VoucherId._(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is VoucherId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'VoucherId($value)';
}
