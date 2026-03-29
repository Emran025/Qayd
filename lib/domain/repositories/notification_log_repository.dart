import 'package:qayd/core/result/result.dart';

/// Audit row for an offline messaging intent (SMS / WhatsApp launcher).
final class NotificationLogEntry {
  const NotificationLogEntry({
    required this.id,
    required this.channel,
    this.templateId,
    required this.entityType,
    required this.entityId,
    required this.renderedBodyPreview,
    required this.status,
    required this.createdAtIso,
  });

  final String id;

  /// `sms` | `whatsapp`
  final String channel;
  final String? templateId;

  /// `voucher` | `account`
  final String entityType;
  final String entityId;
  final String renderedBodyPreview;

  /// e.g. `intent_launched`
  final String status;
  final String createdAtIso;
}

abstract interface class NotificationLogRepository {
  Future<Result<void>> insert(NotificationLogEntry entry);
}
