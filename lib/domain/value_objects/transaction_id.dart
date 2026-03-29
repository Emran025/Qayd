/// Groups ledger entries that belong to one balanced double-entry transaction.
final class TransactionId {
  const TransactionId._(this.value);

  final String value;

  factory TransactionId(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'TransactionId must be non-empty');
    }
    return TransactionId._(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is TransactionId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'TransactionId($value)';
}
