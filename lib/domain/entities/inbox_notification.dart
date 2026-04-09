import 'package:flutter/foundation.dart';

@immutable
class InboxNotification {
  const InboxNotification({
    required this.id,
    required this.senderName,
    required this.title,
    required this.body,
    required this.isRead,
    required this.receivedAt,
    required this.actionRoute,
  });

  /// Internal local ID after decryption
  final String id;

  /// Counterpart Account Name
  final String senderName;

  /// e.g. "New Claim", "Voucher Accepted"
  final String title;

  /// e.g. "Sent you a receipt voucher for 1,000 SAR"
  final String body;

  /// Visually separates unseen badges
  final bool isRead;

  final DateTime receivedAt;

  /// Deep link inside the app to jump to the relevant Chat / Voucher ID
  final String actionRoute;
}
