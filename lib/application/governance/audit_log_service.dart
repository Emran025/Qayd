import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';
import 'package:uuid/uuid.dart';

/// Core audit service: records mutations, drives undo/redo, and owns the
/// schema-aware recovery engine.
///
/// ## Architecture
///
/// The audit trail is a *linear time-line* with a HEAD pointer.  Every live
/// entry that has `isUndone = false` is part of the canonical history; every
/// entry with `isUndone = true` sits on the orphaned "redo branch".  When the
/// user performs a new mutation after an undo, the redo branch is **pruned**
/// — the same behaviour as git's non-rebased commits.
///
/// ## Safety guarantees
///
/// * All schema inspection uses `PRAGMA table_info` and
///   `PRAGMA foreign_key_list` so that restoration never hits
///   "no such column" errors regardless of schema evolution.
/// * Column values are filtered through [_filterColumns] before any INSERT or
///   UPDATE to prevent injection via stale snapshot data.
/// * Foreign-key constraints are respected via a recursive, topologically
///   sorted cascade engine (`_cascadeDelete` / `_restoreChildren`).
/// * The FK graph is built once and cached.  Call [invalidateSchemaCache] if
///   the schema changes at runtime (e.g., during migration on app upgrade).
class AuditLogService {
  final AuditLogRepository auditRepo;
  final Database database;

  AuditLogService({
    required this.auditRepo,
    required this.database,
  });

  // ── Schema cache ─────────────────────────────────────────────────────────────

  /// parentTable → list of {childTable, fromColumn} relationships.
  Map<String, List<Map<String, String>>>? _fkGraph;

  /// table → primary-key column name.
  Map<String, String>? _pkCache;

  /// table → set of valid column names.
  Map<String, Set<String>>? _columnCache;

  /// Clears the schema caches so they are rebuilt on next access.
  /// Call this after a live schema migration.
  void invalidateSchemaCache() {
    _fkGraph = null;
    _pkCache = null;
    _columnCache = null;
  }

  // ── Public API ───────────────────────────────────────────────────────────────

  /// Records a single mutation in the audit trail.
  ///
  /// Automatically prunes the redo branch (all `isUndone = true` entries)
  /// so that a new action always creates a fresh linear history from the
  /// current HEAD.
  Future<void> log({
    String? batchId,
    String? actorId,
    required String entityType,
    required String entityId,
    required AuditAction action,
    AuditSeverity? severity,
    Map<String, dynamic>? oldData,
    Map<String, dynamic>? newData,
  }) async {
    await _pruneRedoBranch();

    final resolvedSeverity = severity ?? _inferSeverity(action);
    final now = DateTime.now().toUtc();

    final entry = AuditEntry(
      id: '${now.microsecondsSinceEpoch}_${const Uuid().v4().substring(0, 8)}',
      batchId: batchId,
      actorId: actorId,
      entityType: entityType,
      entityId: entityId,
      action: action,
      severity: resolvedSeverity,
      oldData: oldData,
      newData: newData,
      createdAt: now,
    );

    await auditRepo.save(entry);
    _debugLog('[AuditLog] ✏️ ${action.label} $entityType/$entityId');
  }

  /// Returns all entries, newest-first.
  Future<List<AuditEntry>> getQueue() => auditRepo.listAll();

  // ── Rollback / Redo ──────────────────────────────────────────────────────────

  /// Rolls back every active entry **newer than** the entry with [auditEntryId],
  /// making [auditEntryId] the new HEAD.
  ///
  /// Entries are reverted in order from newest to oldest (reverse application
  /// order) to satisfy FK constraints.
  Future<void> rollbackTo(String auditEntryId) async {
    final all = await auditRepo.listAll(); // Newest first
    final targetIndex = all.indexWhere((e) => e.id == auditEntryId);
    if (targetIndex == -1) {
      _debugLog('[AuditLog] ⚠️ rollbackTo: target $auditEntryId not found.');
      return;
    }

    // All entries *newer* than the target (index 0..targetIndex-1) must be reverted.
    final toRevert = all.sublist(0, targetIndex);

    for (final entry in toRevert) {
      if (!entry.isUndone) {
        _debugLog(
            '[AuditLog] ↩️ Reverting ${entry.action.label} ${entry.entityType}/${entry.entityId}');
        final enriched = await _revertSingle(entry);
        await auditRepo.update(enriched.copyWith(isUndone: true));
      }
    }
  }

  /// Re-applies every undone entry between the current HEAD and [auditEntryId],
  /// making [auditEntryId] the new HEAD.
  Future<void> redoTo(String auditEntryId) async {
    final all = await auditRepo.listAll(); // Newest first
    final targetIndex = all.indexWhere((e) => e.id == auditEntryId);
    if (targetIndex == -1) {
      _debugLog('[AuditLog] ⚠️ redoTo: target $auditEntryId not found.');
      return;
    }

    // The first active (non-undone) entry index == HEAD.
    final headIndex = all.indexWhere((e) => !e.isUndone);
    final limitIndex = headIndex == -1 ? all.length : headIndex;

    // Apply in forward (chronological) order: from oldest undone to target.
    for (int i = limitIndex - 1; i >= targetIndex; i--) {
      final entry = all[i];
      if (entry.isUndone) {
        _debugLog(
            '[AuditLog] ↪️ Redoing ${entry.action.label} ${entry.entityType}/${entry.entityId}');
        await _applySingle(entry);
        await auditRepo.update(entry.copyWith(isUndone: false));
      }
    }
  }

  // ── Single-entry revert (new) ─────────────────────────────────────────────────

  /// Returns the list of **active** (non-undone) entries that are **newer** than
  /// the entry with [auditEntryId] and share the same [entityId] or reference it
  /// in their data — i.e., entries that would be implicitly broken if
  /// [auditEntryId] were independently reverted.
  ///
  /// This is used by the UI to warn the user before committing to a revert.
  Future<List<AuditEntry>> getEntriesAffectedByRevert(
      String auditEntryId) async {
    final all = await auditRepo.listAll(); // Newest first
    final targetIndex = all.indexWhere((e) => e.id == auditEntryId);
    if (targetIndex == -1) return [];

    final target = all[targetIndex];

    // All active entries that are *newer* than the target (index < targetIndex).
    final newer = all.sublist(0, targetIndex).where((e) => !e.isUndone);

    // An entry is "affected" if it touches the same entity or references the
    // target entity's ID in its data payload.
    final entityId = target.entityId;
    return newer.where((e) {
      if (e.entityId == entityId) return true;
      // Check if the newer entry's data references the target entity ID.
      final dataStr = [
        e.oldData?.toString() ?? '',
        e.newData?.toString() ?? '',
      ].join();
      return dataStr.contains(entityId);
    }).toList();
  }

  /// Reverts **only** the single entry identified by [auditEntryId], without
  /// touching any other entries on the timeline.
  ///
  /// The entry is marked `isUndone = true` after the DB-level revert is applied.
  /// Callers should use [getEntriesAffectedByRevert] first to warn the user
  /// if dependent entries exist.
  Future<void> revertSingleEntry(String auditEntryId) async {
    final all = await auditRepo.listAll();
    final entry = all.firstWhere(
      (e) => e.id == auditEntryId,
      orElse: () => throw StateError(
          '[AuditLog] revertSingleEntry: $auditEntryId not found.'),
    );

    if (entry.isUndone) {
      _debugLog('[AuditLog] revertSingleEntry: $auditEntryId already undone.');
      return;
    }

    _debugLog(
        '[AuditLog] ✂️ Reverting single ${entry.action.label} ${entry.entityType}/${entry.entityId}');
    final enriched = await _revertSingle(entry);
    await auditRepo.update(enriched.copyWith(isUndone: true));
  }

  /// Re-applies a previously reverted single entry (redo for a single entry).
  Future<void> redoSingleEntry(String auditEntryId) async {
    final all = await auditRepo.listAll();
    final entry = all.firstWhere(
      (e) => e.id == auditEntryId,
      orElse: () => throw StateError(
          '[AuditLog] redoSingleEntry: $auditEntryId not found.'),
    );

    if (!entry.isUndone) {
      _debugLog('[AuditLog] redoSingleEntry: $auditEntryId is not undone.');
      return;
    }

    _debugLog(
        '[AuditLog] ▶️ Re-applying single ${entry.action.label} ${entry.entityType}/${entry.entityId}');
    await _applySingle(entry);
    await auditRepo.update(entry.copyWith(isUndone: false));
  }

  /// Undoes all entries belonging to [batchId] (newest-first).
  Future<void> undoBatch(String batchId) async {
    final entries = await auditRepo.getByBatchId(batchId); // Newest first
    for (final entry in entries) {
      if (!entry.isUndone) {
        final enriched = await _revertSingle(entry);
        await auditRepo.update(enriched.copyWith(isUndone: true));
      }
    }
  }

  /// Re-applies all entries belonging to [batchId] (oldest-first).
  Future<void> redoBatch(String batchId) async {
    final entries = await auditRepo.getByBatchId(batchId); // Newest first
    for (final entry in entries.reversed) {
      if (entry.isUndone) {
        await _applySingle(entry);
        await auditRepo.update(entry.copyWith(isUndone: false));
      }
    }
  }

  // ── Redo branch pruning ──────────────────────────────────────────────────────

  /// Deletes all `isUndone = true` entries so that a new mutation creates a
  /// clean, linear history from the current state.
  Future<void> _pruneRedoBranch() async {
    await auditRepo.deleteUndoneAfter(
      DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }

  // ── Revert engine ────────────────────────────────────────────────────────────

  /// Reverts a single [entry] against the live database.
  ///
  /// Returns the (potentially enriched) entry — callers must persist the
  /// returned value.
  Future<AuditEntry> _revertSingle(AuditEntry entry) async {
    final table = _tableFor(entry.entityType);
    final id = entry.entityId;
    AuditEntry result = entry;

    switch (entry.action) {
      case AuditAction.create:
        // Undo CREATE → DELETE.
        // Snapshot the exact DB row *before* deletion so Redo can recreate it.
        final parentRows =
            await database.query(table, where: 'id = ?', whereArgs: [id]);
        final childrenBackup = await _backupChildren(table, id);

        await _cascadeDelete(table, id);
        await database.delete(table, where: 'id = ?', whereArgs: [id]);

        // Enrich oldData with DB-level snapshots for accurate Redo.
        if (parentRows.isNotEmpty || childrenBackup.isNotEmpty) {
          final enriched = Map<String, dynamic>.from(entry.oldData ?? {});
          if (parentRows.isNotEmpty) enriched['_parent'] = parentRows.first;
          if (childrenBackup.isNotEmpty) enriched['_children'] = childrenBackup;
          result = entry.copyWith(oldData: enriched);
        }

      case AuditAction.update:
        // Undo UPDATE → apply oldData.
        if (entry.oldData != null) {
          final data = Map<String, dynamic>.from(entry.oldData!)
            ..remove('_children')
            ..remove('_parent');
          final safe = await _filterColumns(table, data);
          if (safe.isNotEmpty) {
            await _safeExecute(() => database.update(
                  table,
                  safe,
                  where: 'id = ?',
                  whereArgs: [id],
                ));
          }
        }

      case AuditAction.delete:
        // Undo DELETE → re-INSERT from oldData.
        if (entry.oldData != null) {
          final data = Map<String, dynamic>.from(entry.oldData!);
          final children = data.remove('_children') as Map<String, dynamic>?;

          final parentRow = data.containsKey('_parent')
              ? Map<String, dynamic>.from(data.remove('_parent') as Map)
              : data;
          parentRow.remove('_parent');

          final safe = await _filterColumns(table, parentRow);
          if (safe.isNotEmpty) {
            await _safeExecute(() => database.insert(
                  table,
                  safe,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                ));
          }

          if (children != null) {
            await _restoreChildren(table, children);
          }
        }

      case AuditAction.revert:
        // Revert entries are metadata — no DB action needed.
        break;
    }

    return result;
  }

  // ── Apply engine (Redo) ──────────────────────────────────────────────────────

  /// Re-applies a single [entry] against the live database.
  Future<void> _applySingle(AuditEntry entry) async {
    final table = _tableFor(entry.entityType);
    final id = entry.entityId;

    switch (entry.action) {
      case AuditAction.create:
        // Redo CREATE → re-INSERT using the accurate DB snapshot if available.
        bool inserted = false;

        if (entry.oldData != null && entry.oldData!.containsKey('_parent')) {
          final parentRow = Map<String, dynamic>.from(
              entry.oldData!['_parent'] as Map);
          final safe = await _filterColumns(table, parentRow);
          if (safe.isNotEmpty) {
            await _safeExecute(() => database.insert(
                  table,
                  safe,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                ));
            inserted = true;
          }
        } else if (entry.newData != null) {
          // Fallback: use newData for entries recorded before schema enrichment.
          final safe = await _filterColumns(table, entry.newData!);
          if (safe.isNotEmpty) {
            inserted = await _safeExecute(() => database.insert(
                      table,
                      safe,
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    )) !=
                null;
          }
        }

        if (!inserted) return;

        if (entry.hasChildrenBackup) {
          await _restoreChildren(
            table,
            entry.oldData!['_children'] as Map<String, dynamic>,
          );
        }

      case AuditAction.update:
        // Redo UPDATE → apply newData.
        if (entry.newData != null) {
          final data = Map<String, dynamic>.from(entry.newData!)
            ..remove('_children')
            ..remove('_parent');
          final safe = await _filterColumns(table, data);
          if (safe.isNotEmpty) {
            await _safeExecute(() => database.update(
                  table,
                  safe,
                  where: 'id = ?',
                  whereArgs: [id],
                ));
          }
        }

      case AuditAction.delete:
        // Redo DELETE → backup then cascade-delete.
        final parentRows =
            await database.query(table, where: 'id = ?', whereArgs: [id]);
        final childrenBackup = await _backupChildren(table, id);

        if (parentRows.isNotEmpty || childrenBackup.isNotEmpty) {
          final enriched = Map<String, dynamic>.from(entry.oldData ?? {});
          if (parentRows.isNotEmpty) enriched['_parent'] = parentRows.first;
          if (childrenBackup.isNotEmpty) enriched['_children'] = childrenBackup;
          await auditRepo.update(entry.copyWith(oldData: enriched));
        }

        await _cascadeDelete(table, id);
        await database.delete(table, where: 'id = ?', whereArgs: [id]);

      case AuditAction.revert:
        break;
    }
  }

  // ── Schema inspection ────────────────────────────────────────────────────────

  Future<void> _ensureSchemaLoaded() async {
    if (_fkGraph != null) return;

    _fkGraph = {};
    _pkCache = {};
    _columnCache = {};

    final tablesResult = await database
        .rawQuery("SELECT name FROM sqlite_master WHERE type='table'");
    final tables = tablesResult
        .map((r) => r['name'] as String)
        .where((t) => !t.startsWith('sqlite_') && !t.startsWith('android_'))
        .toList();

    for (final table in tables) {
      // --- Column set ---
      final colInfo =
          await database.rawQuery("PRAGMA table_info('$table')");
      final columns = <String>{};
      for (final col in colInfo) {
        final name = col['name'] as String;
        columns.add(name);
        if (col['pk'] == 1 && !_pkCache!.containsKey(table)) {
          _pkCache![table] = name;
        }
      }
      _columnCache![table] = columns;

      // --- Foreign key map ---
      final fks = await database
          .rawQuery("PRAGMA foreign_key_list('$table')");
      for (final fk in fks) {
        final parent = fk['table'] as String;
        final from = fk['from'] as String;
        _fkGraph!.putIfAbsent(parent, () => []);
        _fkGraph![parent]!.add({'childTable': table, 'fromColumn': from});
      }
    }
  }

  /// Returns only the keys from [data] that correspond to real columns in [table].
  Future<Map<String, dynamic>> _filterColumns(
      String table, Map<String, dynamic> data) async {
    await _ensureSchemaLoaded();
    final valid = _columnCache![table] ?? {};
    return {
      for (final e in data.entries)
        if (valid.contains(e.key)) e.key: e.value,
    };
  }

  // ── Cascade delete ───────────────────────────────────────────────────────────

  Future<void> _cascadeDelete(String parentTable, String parentId) async {
    await _ensureSchemaLoaded();
    await _recursiveDelete(parentTable, parentId);
  }

  Future<void> _recursiveDelete(String parentTable, String parentId) async {
    for (final dep in _fkGraph![parentTable] ?? <Map<String, String>>[]) {
      final childTable = dep['childTable']!;
      final fkCol = dep['fromColumn']!;
      final pkCol = _pkCache![childTable];

      if (pkCol != null) {
        final children = await database.query(
          childTable,
          columns: [pkCol],
          where: '$fkCol = ?',
          whereArgs: [parentId],
        );
        for (final row in children) {
          final childId = row[pkCol];
          if (childId != null) {
            await _recursiveDelete(childTable, childId.toString());
          }
        }
      }

      await database.delete(
        childTable,
        where: '$fkCol = ?',
        whereArgs: [parentId],
      );
    }
  }

  // ── Children backup & restore ────────────────────────────────────────────────

  Future<Map<String, dynamic>> _backupChildren(
      String parentTable, String parentId) async {
    await _ensureSchemaLoaded();
    final backup = <String, dynamic>{};
    await _recursiveBackup(parentTable, parentId, backup);
    return backup;
  }

  Future<void> _recursiveBackup(
    String parentTable,
    String parentId,
    Map<String, dynamic> backup,
  ) async {
    for (final dep in _fkGraph![parentTable] ?? <Map<String, String>>[]) {
      final childTable = dep['childTable']!;
      final fkCol = dep['fromColumn']!;

      final rows = await database.query(
        childTable,
        where: '$fkCol = ?',
        whereArgs: [parentId],
      );
      if (rows.isEmpty) continue;

      backup.putIfAbsent(childTable, () => <Map<String, dynamic>>[]);
      (backup[childTable] as List).addAll(rows);

      final pkCol = _pkCache![childTable];
      if (pkCol != null) {
        for (final row in rows) {
          final childId = row[pkCol];
          if (childId != null) {
            await _recursiveBackup(childTable, childId.toString(), backup);
          }
        }
      }
    }
  }

  Future<void> _restoreChildren(
      String rootTable, Map<String, dynamic> children) async {
    await _ensureSchemaLoaded();
    // Restore top-down so parent FKs are satisfied before children are inserted.
    final orderedTables = _topDownOrder(rootTable);

    for (final childTable in orderedTables) {
      if (childTable == rootTable) continue;
      final rows = children[childTable];
      if (rows == null) continue;

      for (final raw in rows as List) {
        final safe = await _filterColumns(
            childTable, Map<String, dynamic>.from(raw as Map));
        if (safe.isEmpty) continue;
        await _safeExecute(() => database.insert(
              childTable,
              safe,
              conflictAlgorithm: ConflictAlgorithm.replace,
            ));
      }
    }
  }

  /// BFS over the FK graph to produce a stable top-down insertion order.
  List<String> _topDownOrder(String root) {
    final order = <String>[];
    final queue = [root];
    while (queue.isNotEmpty) {
      final node = queue.removeAt(0);
      if (!order.contains(node)) order.add(node);
      for (final dep in _fkGraph![node] ?? <Map<String, String>>[]) {
        queue.add(dep['childTable']!);
      }
    }
    return order;
  }

  // ── Table name resolution ────────────────────────────────────────────────────

  /// Maps a canonical entity-type string to its SQLite table name.
  static String _tableFor(String entityType) {
    return switch (entityType.toLowerCase()) {
      'voucher' || 'vouchers' => 'vouchers',
      'account' || 'accounts' => 'accounts',
      'collateral' || 'collaterals' => 'collaterals',
      'ledger_entry' || 'ledger_entries' => 'ledger_entries',
      'cost_center' || 'cost_centers' => 'cost_centers',
      'currency' || 'currencies' => 'currencies',
      'attachment' || 'attachments' => 'attachments',
      'accrual' || 'accruals' || 'accrual_component' || 'accrual_components' =>
        'accrual_components',
      'cost_center_dimension' || 'cost_center_dimensions' => 'cost_center_dimensions',
      'transaction_fee' ||
      'transaction_fees' ||
      'transaction_fee_setting' ||
      'transaction_fee_settings' => 'transaction_fees',
      'message_template' || 'message_templates' => 'message_templates',
      'party_details' => 'party_details',
      final t when t.endsWith('y') =>
        '${t.substring(0, t.length - 1)}ies',
      final t when !t.endsWith('s') => '${t}s',
      final t => t,
    };
  }

  // ── Helpers ──────────────────────────────────────────────────────────────────

  /// Infers a [AuditSeverity] from the [action] when none is supplied.
  static AuditSeverity _inferSeverity(AuditAction action) {
    return switch (action) {
      AuditAction.create => AuditSeverity.info,
      AuditAction.update => AuditSeverity.info,
      AuditAction.delete => AuditSeverity.warning,
      AuditAction.revert => AuditSeverity.warning,
    };
  }

  /// Executes [fn] and returns its result, logging but not rethrowing errors.
  ///
  /// Silent failure is only acceptable here because the recovery engine is a
  /// *best-effort* subsystem — the underlying DB state may already be
  /// inconsistent (e.g., old entries referencing dropped columns).
  Future<T?> _safeExecute<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      _debugLog('[AuditLog] ⚠️ Recovery step failed (non-fatal): $e\n$st');
      return null;
    }
  }

  static void _debugLog(String message) {
    if (kDebugMode) debugPrint(message);
  }
}
