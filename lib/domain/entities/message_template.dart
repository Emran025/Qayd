import 'package:qayd/domain/value_objects/message_template_kind.dart';

/// User-editable message pattern with `{{placeholder}}` tokens (persisted in SQLite).
final class MessageTemplate {
  const MessageTemplate({
    required this.id,
    required this.kind,
    required this.name,
    required this.body,
    required this.isSystem,
    required this.sortOrder,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final MessageTemplateKind kind;
  final String name;
  final String body;
  final bool isSystem;
  final int sortOrder;
  final DateTime createdAt;
  final DateTime updatedAt;
}
