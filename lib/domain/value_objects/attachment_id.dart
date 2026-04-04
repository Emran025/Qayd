/// Strongly-typed identifier for voucher attachments.
final class AttachmentId {
  const AttachmentId(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AttachmentId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => 'AttachmentId($value)';
}
