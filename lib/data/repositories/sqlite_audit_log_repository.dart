import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SqliteAuditLogRepository implements AuditLogRepository {
  final Database _db;
  bool? _hasSyncColumns;

  SqliteAuditLogRepository(this._db);

  static const _table = 'audit_logs';

  // ── Write ───────────────────────────────────────────────────────────────────

  @override
  Future<void> save(AuditEntry entry) async {
    await _ensureSyncColumns();
    final map = entry.toMap();
    if (_hasSyncColumns == true) {
      if (entry.syncSeq != null) {
        map['sync_seq'] = entry.syncSeq;
      } else {
        final maxSeq = Sqflite.firstIntValue(
              await _db.rawQuery('SELECT MAX(sync_seq) FROM $_table'),
            ) ??
            0;
        map['sync_seq'] = maxSeq + 1;
      }
      map['device_id'] ??= _extractDeviceId(entry.actorId);
    }
    await _db.insert(
      _table,
      map,
      conflictAlgorithm: ConflictAlgorithm.rollback,
    );
  }

  @override
  Future<void> update(AuditEntry entry) async {
    await _ensureSyncColumns();
    final map = entry.toMap();
    if (_hasSyncColumns == true) {
      map['device_id'] ??= _extractDeviceId(entry.actorId);
    }
    await _db.update(
      _table,
      map,
      where: 'id = ?',
      whereArgs: [entry.id],
    );
  }

  // ── Read ────────────────────────────────────────────────────────────────────

  @override
  Future<List<AuditEntry>> listAll() async {
    final rows = await _db.query(_table, orderBy: 'created_at DESC');
    return rows.map(AuditEntry.fromMap).toList();
  }

  @override
  Future<List<AuditEntry>> getByBatchId(String batchId) async {
    final rows = await _db.query(
      _table,
      where: 'batch_id = ?',
      whereArgs: [batchId],
      orderBy: 'created_at DESC',
    );
    return rows.map(AuditEntry.fromMap).toList();
  }

  @override
  Future<List<AuditEntry>> getByEntity(
      String entityType, String entityId) async {
    final rows = await _db.query(
      _table,
      where: 'entity_type = ? AND entity_id = ?',
      whereArgs: [entityType, entityId],
      orderBy: 'created_at DESC',
    );
    return rows.map(AuditEntry.fromMap).toList();
  }

  @override
  Future<List<AuditEntry>> listActive() async {
    final rows = await _db.query(
      _table,
      where: 'is_undone = 0',
      orderBy: 'created_at DESC',
    );
    return rows.map(AuditEntry.fromMap).toList();
  }

  @override
  Future<List<AuditEntry>> listSinceSeq(int seq) async {
    await _ensureSyncColumns();
    if (_hasSyncColumns != true) return <AuditEntry>[];
    final rows = await _db.query(
      _table,
      where: 'sync_seq > ?',
      whereArgs: [seq],
      orderBy: 'sync_seq ASC',
    );
    return rows.map(AuditEntry.fromMap).toList();
  }

  @override
  Future<AuditEntry?> getLatest() async {
    final rows = await _db.query(
      _table,
      where: 'is_undone = 0',
      orderBy: 'created_at DESC',
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return AuditEntry.fromMap(rows.first);
  }

  @override
  Future<int> countAll() async {
    final result = await _db.rawQuery('SELECT COUNT(*) as cnt FROM $_table');
    return (result.first['cnt'] as int?) ?? 0;
  }

  // ── Cleanup ─────────────────────────────────────────────────────────────────

  @override
  Future<void> clear() async {
    await _db.delete(_table);
  }

  @override
  Future<void> deleteAfter(DateTime timestamp) async {
    await _db.delete(
      _table,
      where: 'created_at > ?',
      whereArgs: [timestamp.toUtc().toIso8601String()],
    );
  }

  @override
  Future<void> deleteUndoneAfter(DateTime timestamp) async {
    await _db.delete(
      _table,
      where: 'created_at > ? AND is_undone = 1',
      whereArgs: [timestamp.toUtc().toIso8601String()],
    );
  }

  Future<void> _ensureSyncColumns() async {
    if (_hasSyncColumns != null) return;
    final columns = await _db.rawQuery('PRAGMA table_info($_table)');
    final names = columns.map((row) => row['name'] as String? ?? '').toSet();
    _hasSyncColumns = names.contains('sync_seq') && names.contains('device_id');
  }

  String? _extractDeviceId(String? actorId) {
    if (actorId == null || !actorId.startsWith('device:')) return null;
    final parts = actorId.split(':');
    if (parts.length < 2) return null;
    return parts.sublist(1).join(':');
  }
}
