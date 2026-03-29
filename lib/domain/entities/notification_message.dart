/// Raw notification text stored for offline voucher suggestions.
final class NotificationMessage {
  const NotificationMessage({
    required this.id,
    required this.bodyText,
    this.channel,
    required this.counterpartyAccountId,
    required this.createdAt,
    required this.processed,
  });

  final String id;
  final String bodyText;
  final String? channel;
  final String counterpartyAccountId;
  final DateTime createdAt;
  final bool processed;
}
