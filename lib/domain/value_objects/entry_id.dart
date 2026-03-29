/// Strongly typed identifier for a single ledger entry line.
final class EntryId {
  const EntryId._(this.value);

  final String value;

  factory EntryId(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'EntryId must be non-empty');
    }
    return EntryId._(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EntryId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'EntryId($value)';
}
