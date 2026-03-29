/// Strongly typed identifier for an account in the chart of accounts.
final class AccountId {
  const AccountId._(this.value);

  final String value;

  factory AccountId(String raw) {
    final v = raw.trim();
    if (v.isEmpty) {
      throw ArgumentError.value(raw, 'raw', 'AccountId must be non-empty');
    }
    return AccountId._(v);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is AccountId && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AccountId($value)';
}
