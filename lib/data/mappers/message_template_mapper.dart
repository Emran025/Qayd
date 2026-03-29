import 'package:qayd/data/models/message_template_model.dart';
import 'package:qayd/domain/entities/message_template.dart';
import 'package:qayd/domain/value_objects/message_template_kind.dart';

abstract final class MessageTemplateMapper {
  static MessageTemplate toEntity(MessageTemplateModel m) {
    final kind = MessageTemplateKind.fromStorage(m.kind);
    if (kind == null) {
      throw StateError('Unknown template kind: ${m.kind}');
    }
    return MessageTemplate(
      id: m.id,
      kind: kind,
      name: m.name,
      body: m.body,
      isSystem: m.isSystem,
      sortOrder: m.sortOrder,
      createdAt: DateTime.parse(m.createdAtIso),
      updatedAt: DateTime.parse(m.updatedAtIso),
    );
  }

  static MessageTemplateModel toModel(MessageTemplate e) {
    return MessageTemplateModel(
      id: e.id,
      kind: e.kind.storageCode,
      name: e.name,
      body: e.body,
      isSystem: e.isSystem,
      sortOrder: e.sortOrder,
      createdAtIso: e.createdAt.toIso8601String(),
      updatedAtIso: e.updatedAt.toIso8601String(),
    );
  }
}
