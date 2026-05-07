import 'package:qayd/domain/entities/device_session.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

class SqliteDeviceSessionRepository implements DeviceSessionRepository {
  const SqliteDeviceSessionRepository(this._db);

  final Database _db;
  static const _table = 'device_sessions';

  @override
  Future<void> upsert(DeviceSession session) async {
    await _db.insert(
      _table,
      session.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<DeviceSession>> listAll() async {
    final rows = await _db.query(_table, orderBy: 'paired_at DESC');
    return rows.map(DeviceSession.fromMap).toList();
  }

  @override
  Future<List<DeviceSession>> listActive() async {
    final rows = await _db.query(
      _table,
      where: 'is_active = 1',
      orderBy: 'paired_at DESC',
    );
    return rows.map(DeviceSession.fromMap).toList();
  }

  @override
  Future<DeviceSession?> getById(String deviceId) async {
    final rows = await _db.query(
      _table,
      where: 'device_id = ?',
      whereArgs: [deviceId],
      limit: 1,
    );
    if (rows.isEmpty) return null;
    return DeviceSession.fromMap(rows.first);
  }

  @override
  Future<void> setActive(String deviceId, bool isActive) async {
    await _db.update(
      _table,
      {'is_active': isActive ? 1 : 0},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  @override
  Future<void> updateLastSyncSeq(String deviceId, int lastSyncSeq) async {
    await _db.update(
      _table,
      {'last_sync_seq': lastSyncSeq},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }

  @override
  Future<void> updateLastSeen(String deviceId, DateTime at) async {
    await _db.update(
      _table,
      {'last_seen_at': at.toUtc().toIso8601String()},
      where: 'device_id = ?',
      whereArgs: [deviceId],
    );
  }
}
