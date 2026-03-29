final class MessageTemplateModel {
  const MessageTemplateModel({
    required this.id,
    required this.kind,
    required this.name,
    required this.body,
    required this.isSystem,
    required this.sortOrder,
    required this.createdAtIso,
    required this.updatedAtIso,
  });

  final String id;
  final String kind;
  final String name;
  final String body;
  final bool isSystem;
  final int sortOrder;
  final String createdAtIso;
  final String updatedAtIso;

  Map<String, Object?> toMap() => {
        'id': id,
        'kind': kind,
        'name': name,
        'body': body,
        'is_system': isSystem ? 1 : 0,
        'sort_order': sortOrder,
        'created_at': createdAtIso,
        'updated_at': updatedAtIso,
      };

  factory MessageTemplateModel.fromMap(Map<String, Object?> map) {
    return MessageTemplateModel(
      id: map['id']! as String,
      kind: map['kind']! as String,
      name: map['name']! as String,
      body: map['body']! as String,
      isSystem: (map['is_system'] as int) != 0,
      sortOrder: map['sort_order']! as int,
      createdAtIso: map['created_at']! as String,
      updatedAtIso: map['updated_at']! as String,
    );
  }
}
