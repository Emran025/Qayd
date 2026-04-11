import 'dart:convert';

enum AuditAction { create, update, delete, revert }

class AuditEntry {
  final String id;
  final String entityType;
  final String entityId;
  final AuditAction action;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final DateTime createdAt;

  AuditEntry({
    required this.id,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.oldData,
    this.newData,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action.name,
      'old_data': oldData != null ? jsonEncode(oldData) : null,
      'new_data': newData != null ? jsonEncode(newData) : null,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'] as String,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      action: AuditAction.values.firstWhere((e) => e.name == map['action']),
      oldData: map['old_data'] != null ? jsonDecode(map['old_data'] as String) as Map<String, dynamic> : null,
      newData: map['new_data'] != null ? jsonDecode(map['new_data'] as String) as Map<String, dynamic> : null,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }
}
