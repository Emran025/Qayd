import 'dart:convert';

/// The type of database mutation captured by an [AuditEntry].
enum AuditAction {
  create,
  update,
  delete,
  revert;

  /// Human-readable label (for logging / debugging — not for UI).
  String get label => switch (this) {
        AuditAction.create => 'CREATE',
        AuditAction.update => 'UPDATE',
        AuditAction.delete => 'DELETE',
        AuditAction.revert => 'REVERT',
      };

  static AuditAction fromString(String value) {
    return AuditAction.values.firstWhere(
      (e) => e.name == value.toLowerCase(),
      orElse: () => throw ArgumentError('Unknown AuditAction: $value'),
    );
  }
}

/// Importance level of an audit entry — used to drive UI and retention policy.
enum AuditSeverity {
  /// Informational mutations (create, routine update).
  info,

  /// Mutations that delete or significantly alter financial data.
  warning,

  /// Unrecoverable or security-sensitive mutations.
  critical;

  static AuditSeverity fromString(String? value) {
    return AuditSeverity.values.firstWhere(
      (e) => e.name == value?.toLowerCase(),
      orElse: () => AuditSeverity.info,
    );
  }
}

/// An immutable record of a single database mutation.
///
/// The payload fields [oldData] and [newData] are the DB-level snapshots
/// (i.e., column → value maps), not UI representations.
///
/// The reserved key `_children` inside [oldData] holds a
/// `Map<tableName, List<Map>>` snapshot of cascaded child rows, which the
/// recovery engine uses to reconstruct the full relational state.
class AuditEntry {
  final String id;
  final String? batchId;
  final String? actorId;
  final String entityType;
  final String entityId;
  final AuditAction action;
  final AuditSeverity severity;
  final Map<String, dynamic>? oldData;
  final Map<String, dynamic>? newData;
  final bool isUndone;
  final DateTime createdAt;
  final int? syncSeq;

  const AuditEntry({
    required this.id,
    this.batchId,
    this.actorId,
    required this.entityType,
    required this.entityId,
    required this.action,
    this.severity = AuditSeverity.info,
    this.oldData,
    this.newData,
    this.isUndone = false,
    required this.createdAt,
    this.syncSeq,
  });

  // ── Derived helpers ──────────────────────────────────────────────────────────

  /// Returns [oldData] stripped of internal recovery metadata keys.
  Map<String, dynamic>? get cleanOldData {
    if (oldData == null) return null;
    final clean = Map<String, dynamic>.from(oldData!)
      ..remove('_children')
      ..remove('_parent');
    return clean.isEmpty ? null : clean;
  }

  /// Returns [newData] stripped of internal recovery metadata keys.
  Map<String, dynamic>? get cleanNewData {
    if (newData == null) return null;
    final clean = Map<String, dynamic>.from(newData!)
      ..remove('_children')
      ..remove('_parent');
    return clean.isEmpty ? null : clean;
  }

  /// Whether this entry has cascaded child backups stored.
  bool get hasChildrenBackup =>
      oldData != null && oldData!.containsKey('_children');

  // ── Persistence ──────────────────────────────────────────────────────────────

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'batch_id': batchId,
      'actor_id': actorId,
      'entity_type': entityType,
      'entity_id': entityId,
      'action': action.name,
      'severity': severity.name,
      'old_data': oldData != null ? jsonEncode(oldData) : null,
      'new_data': newData != null ? jsonEncode(newData) : null,
      'is_undone': isUndone ? 1 : 0,
      'created_at': createdAt.toUtc().toIso8601String(),
      'sync_seq': syncSeq,
    };
  }

  factory AuditEntry.fromMap(Map<String, dynamic> map) {
    return AuditEntry(
      id: map['id'] as String,
      batchId: map['batch_id'] as String?,
      actorId: map['actor_id'] as String?,
      entityType: map['entity_type'] as String,
      entityId: map['entity_id'] as String,
      action: AuditAction.fromString(map['action'] as String),
      severity: AuditSeverity.fromString(map['severity'] as String?),
      oldData: _decodeJsonColumn(map['old_data']),
      newData: _decodeJsonColumn(map['new_data']),
      isUndone: (map['is_undone'] as int? ?? 0) == 1,
      createdAt: DateTime.parse(map['created_at'] as String).toLocal(),
      syncSeq: map['sync_seq'] as int?,
    );
  }

  // ── Copy with ────────────────────────────────────────────────────────────────

  AuditEntry copyWith({
    String? id,
    String? batchId,
    String? actorId,
    String? entityType,
    String? entityId,
    AuditAction? action,
    AuditSeverity? severity,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
    bool? isUndone,
    DateTime? createdAt,
    int? syncSeq,
  }) {
    return AuditEntry(
      id: id ?? this.id,
      batchId: batchId ?? this.batchId,
      actorId: actorId ?? this.actorId,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      action: action ?? this.action,
      severity: severity ?? this.severity,
      oldData: oldData ?? this.oldData,
      newData: newData ?? this.newData,
      isUndone: isUndone ?? this.isUndone,
      createdAt: createdAt ?? this.createdAt,
      syncSeq: syncSeq ?? this.syncSeq,
    );
  }

  // ── Private helpers ──────────────────────────────────────────────────────────

  static Map<String, dynamic>? _decodeJsonColumn(dynamic raw) {
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw as String);
      if (decoded is Map<String, dynamic>) return decoded;
    } catch (_) {
      // Silently ignore corrupted JSON — old entries may be malformed.
    }
    return null;
  }

  @override
  String toString() =>
      'AuditEntry(id: $id, action: ${action.label}, entity: $entityType/$entityId, undone: $isUndone)';
}
