import 'package:flutter/foundation.dart';
import 'package:qayd/application/sync/audit_sync_compression_service.dart';
import 'package:qayd/application/sync/audit_sync_dispatcher.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/domain/repositories/device_session_repository.dart';
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
  final AuditSyncDispatcher? auditSyncDispatcher;
  final DeviceSessionRepository? deviceSessionRepository;
  final Future<String> Function()? getCurrentDeviceId;

  AuditLogService({
    required this.auditRepo,
    required this.database,
    this.auditSyncDispatcher,
    this.deviceSessionRepository,
    this.getCurrentDeviceId,
  });

  // ── Schema cache ─────────────────────────────────────────────────────────────

  /// parentTable → list of {childTable, fromColumn} relationships.
  Map<String, List<Map<String, String>>>? _fkGraph;

  /// table → primary-key column name.
  Map<String, String>? _pkCache;

  /// table → set of valid column names.
  Map<String, Set<String>>? _columnCache;

  /// When true, [_safeExecute] rethrows FK constraint errors instead of
  /// swallowing them. Set by [replaySyncedEntry] so the sync processor's
  /// retry logic can detect and defer dependent entries.
  bool _rethrowForeignKeyErrors = false;

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
    await _dispatchLiveEntry(entry);
    _debugLog('[AuditLog] ✏️ ${action.label} $entityType/$entityId');
  }

  /// Replays a synced entry from a companion device.
  ///
  /// Unlike local redo, this **rethrows** FK constraint errors so the
  /// [AuditSyncProcessor] retry mechanism can defer the entry and
  /// retry after its dependencies have been inserted.
  Future<void> replaySyncedEntry(AuditEntry entry) async {
    _rethrowForeignKeyErrors = true;
    try {
      await _applySingle(entry);
    } finally {
      _rethrowForeignKeyErrors = false;
    }
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
    final table = tableFor(entry.entityType);
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
    final table = tableFor(entry.entityType);
    final id = entry.entityId;

    switch (entry.action) {
      case AuditAction.create:
        // Redo CREATE → re-INSERT using the accurate DB snapshot if available.
        bool inserted = false;

        if (entry.oldData != null && entry.oldData!.containsKey('_parent')) {
          final parentRow =
              Map<String, dynamic>.from(entry.oldData!['_parent'] as Map);
          final safe = await _filterColumns(table, parentRow);
          if (safe.isNotEmpty) {
            // Companion devices must delete their own randomly-generated seeded accounts
            // to avoid duplicates when receiving the primary's versions.
            // Seeded accounts are identified by: standard_classification != null
            // AND parent_id == null (root accounts). User sub-accounts inherit
            // classification from their parent but have parent_id set.
            if (table == 'accounts' &&
                safe['standard_classification'] != null &&
                safe['parent_id'] == null) {
              await _deleteConflictingLocalAccounts(safe);
            }
            await _safeExecute(() => database.insert(
                  table,
                  safe,
                  conflictAlgorithm: ConflictAlgorithm.replace,
                ));
            inserted = true;
          }
        } else if (entry.newData != null) {
          // Fallback: use newData for entries recorded before schema enrichment.
          // Guard: only attempt INSERT when the PK column is present in the
          // data — partial audit payloads (e.g. {name} only) would otherwise
          // violate NOT NULL constraints on the primary key.
          final safe = await _filterColumns(table, entry.newData!);
          await _ensureSchemaLoaded();
          final pkCol = _pkCache![table];
          final pkPresent =
              pkCol != null && safe.containsKey(pkCol) && safe[pkCol] != null;
          if (safe.isNotEmpty && pkPresent) {
            inserted = await _safeExecute(() => database.insert(
                      table,
                      safe,
                      conflictAlgorithm: ConflictAlgorithm.replace,
                    )) !=
                null;
          } else if (safe.isNotEmpty && !pkPresent) {
            _debugLog(
              '[AuditLog] ⚠️ Skipping CREATE replay for $table: '
              'newData lacks PK column "$pkCol". '
              'Entry was recorded with a partial payload. (entityId=${entry.entityId})',
            );
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
      final colInfo = await database.rawQuery("PRAGMA table_info('$table')");
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
      final fks = await database.rawQuery("PRAGMA foreign_key_list('$table')");
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

  /// Cascade-deletes local seeded accounts that conflict with an incoming
  /// root account from the primary device.
  ///
  /// Seeded accounts are identified by having a `standard_classification`
  /// AND being root accounts (`parent_id IS NULL`).  They may have child
  /// rows (sub-accounts, ledger entries) that block a simple DELETE, so we
  /// cascade-delete each one's children first.
  ///
  /// Note: `is_default` is NOT a reliable identifier — Migration 011 seeds
  /// Payables and Receivables with `is_default = 0`.
  Future<void> _deleteConflictingLocalAccounts(
      Map<String, dynamic> incoming) async {
    await _ensureSchemaLoaded();

    final classification = incoming['standard_classification'];
    if (classification == null) return;

    // Find local root accounts with the same classification.
    // parent_id IS NULL ensures we only match seeded root accounts,
    // not user-created sub-accounts that inherit the classification.
    final conflicting = await database.query(
      'accounts',
      columns: ['id'],
      where: 'standard_classification = ? AND parent_id IS NULL',
      whereArgs: [classification],
    );

    for (final row in conflicting) {
      final conflictId = row['id'] as String;
      if (conflictId == incoming['id']) continue;
      _debugLog(
        '[AuditLog] 🗑️ Cascade-deleting conflicting seeded account '
        '$conflictId (classification=$classification)',
      );
      await _cascadeDelete('accounts', conflictId);
      await database
          .delete('accounts', where: 'id = ?', whereArgs: [conflictId]);
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

  /// DFS over the FK graph to produce a stable top-down insertion order.
  List<String> _topDownOrder(String root) {
    final order = <String>[];
    final visited = <String>{};
    final visiting = <String>{};

    void dfs(String node) {
      if (visited.contains(node)) return;
      if (visiting.contains(node)) return; // Break cycles
      visiting.add(node);

      for (final dep in _fkGraph![node] ?? <Map<String, String>>[]) {
        dfs(dep['childTable']!);
      }

      visiting.remove(node);
      visited.add(node);
      order.add(node);
    }

    dfs(root);
    return order.reversed.toList();
  }

  // ── Table name resolution ────────────────────────────────────────────────────

  /// Maps a canonical entity-type string to its SQLite table name.
  /// Public so DevicePairingService can resolve tables for DB enrichment.
  static String tableFor(String entityType) {

    return switch (entityType.toLowerCase()) {
      'voucher' || 'vouchers' => 'vouchers',
      'account' || 'accounts' => 'accounts',
      'collateral' || 'collaterals' => 'collaterals',
      'ledger_entry' || 'ledger_entries' => 'ledger_entries',
      'cost_center' || 'cost_centers' => 'cost_centers',
      'currency' || 'currencies' => 'currencies',
      'attachment' || 'attachments' => 'attachments',
      'accrual' ||
      'accruals' ||
      'accrual_component' ||
      'accrual_components' =>
        'accrual_components',
      'cost_center_dimension' ||
      'cost_center_dimensions' =>
        'cost_center_dimensions',
      'transaction_fee' ||
      'transaction_fees' ||
      'transaction_fee_setting' ||
      'transaction_fee_settings' =>
        'transaction_fees',
      'message_template' || 'message_templates' => 'message_templates',
      'party_details' => 'party_details',
      final t when t.endsWith('y') => '${t.substring(0, t.length - 1)}ies',
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
  ///
  /// When [_rethrowForeignKeyErrors] is true (set during sync replay),
  /// FK constraint errors are rethrown so the caller can defer and retry.
  Future<T?> _safeExecute<T>(Future<T> Function() fn) async {
    try {
      return await fn();
    } catch (e, st) {
      _debugLog('[AuditLog] ⚠️ Recovery step failed (non-fatal): $e\n$st');
      if (_rethrowForeignKeyErrors && _isForeignKeyError(e)) {
        rethrow;
      }
      return null;
    }
  }

  /// Returns `true` if [error] is a SQLite FOREIGN KEY constraint failure.
  static bool _isForeignKeyError(Object error) {
    final msg = error.toString();
    return msg.contains('FOREIGN KEY constraint failed') ||
        msg.contains('code 787');
  }

  static void _debugLog(String message) {
    if (kDebugMode) debugPrint(message);
  }

  Future<void> _dispatchLiveEntry(AuditEntry entry) async {
    final dispatcher = auditSyncDispatcher;
    final sessionsRepo = deviceSessionRepository;
    if (dispatcher == null || sessionsRepo == null) return;
    if (entry.actorId?.startsWith('sync:') ?? false) return;

    // §D-2: Enrich the entry with a full DB snapshot before dispatching.
    // Audit entries are logged with partial newData (e.g. {id, name, date}).
    // The companion's _applySingle needs oldData['_parent'] to reconstruct
    // the complete row. Without this, CREATEs are silently skipped because
    // partial newData lacks required columns (nature, parent_id, etc.).
    final enrichedEntry = await _enrichForLiveDispatch(entry);

    final currentDeviceId = await getCurrentDeviceId?.call();
    final sessions = await sessionsRepo.listActive();
    for (final session in sessions) {
      if (session.isCurrent) continue;
      if (currentDeviceId != null && session.deviceId == currentDeviceId) {
        continue;
      }
      try {
        await dispatcher.dispatchEntryToDevice(
          entry: enrichedEntry,
          targetDeviceId: session.deviceId,
          receiverPublicKeyHex: session.publicKeyHex,
          reason: SyncPacketReason.liveEvent,
        );
      } catch (e) {
        _debugLog(
            '[AuditLog] ⚠️ live dispatch failed for ${session.deviceId}: $e');
      }
    }
  }

  /// Enriches a single [AuditEntry] with a live DB snapshot so the
  /// companion's recovery engine can reconstruct the complete row.
  ///
  /// For CREATE entries, fetches the current row and embeds it as
  /// `oldData['_parent']` plus any child rows as `oldData['_children']`.
  /// For UPDATE entries, fetches the current row and embeds it as
  /// `newData['_parent']` so the companion has all column values.
  Future<AuditEntry> _enrichForLiveDispatch(AuditEntry entry) async {
    // Only enrich CREATE and UPDATE — DELETE already captures oldData
    // via the revert engine, and REVERT is metadata-only.
    if (entry.action != AuditAction.create &&
        entry.action != AuditAction.update) {
      return entry;
    }

    // Already enriched (has a full DB snapshot).
    if (entry.action == AuditAction.create &&
        entry.oldData != null &&
        entry.oldData!.containsKey('_parent')) {
      return entry;
    }

    try {
      final table = tableFor(entry.entityType);
      final rows = await database
          .query(table, where: 'id = ?', whereArgs: [entry.entityId]);
      if (rows.isEmpty) return entry;

      if (entry.action == AuditAction.create) {
        // Embed the full row as _parent so _applySingle can INSERT it.
        final childrenBackup = await _backupChildren(table, entry.entityId);
        final enrichedOldData = <String, dynamic>{
          ...?entry.oldData,
          '_parent': rows.first,
          if (childrenBackup.isNotEmpty) '_children': childrenBackup,
        };
        return entry.copyWith(oldData: enrichedOldData);
      } else {
        // UPDATE: embed the full current row in newData so the companion
        // can apply a complete UPDATE rather than a partial one.
        final enrichedNewData = <String, dynamic>{
          ...rows.first,
          ...?entry.newData,
        };
        return entry.copyWith(newData: enrichedNewData);
      }
    } catch (e) {
      // Non-fatal: table might not exist for this entityType.
      _debugLog(
          '[AuditLog] ⚠️ Live dispatch enrichment failed for ${entry.entityType}/${entry.entityId}: $e');
      return entry;
    }
  }

  /// § Sync Repair: Ensure all confirmed/settled vouchers have ledger entries
  /// This repairs legacy vouchers synced from primary devices before AuditLog
  /// correctly tracked ledger_entry creations.
  Future<void> repairMissingLedgerEntries() async {
    try {
      final nowStr = DateTime.now().toUtc().toIso8601String();
      final List<Map<String, dynamic>> missing = await database.rawQuery('''
        SELECT v.id, v.type, v.amount_minor, v.currency_code, v.date, v.affected_account_id, v.counterparty_id
        FROM vouchers v
        WHERE v.state IN ('confirmed', 'settled')
        AND NOT EXISTS (
          SELECT 1 FROM ledger_entries e WHERE e.voucher_id = v.id
        )
      ''');

      if (missing.isNotEmpty) {
        _debugLog('[AuditLog] 🛠️ Found ${missing.length} confirmed vouchers missing ledger entries. Repairing...');
        await database.transaction((txn) async {
          for (final row in missing) {
            final voucherId = row['id'] as String;
            final type = row['type'] as String;
            final amount = row['amount_minor'] as int;
            final currency = row['currency_code'] as String;
            final date = row['date'] as String;
            final affected = row['affected_account_id'] as String;
            final counterparty = row['counterparty_id'] as String;

            final transactionId = const Uuid().v4();
            final debitId = const Uuid().v4();
            final creditId = const Uuid().v4();

            final debitAccountId = type == 'receipt' ? affected : counterparty;
            final creditAccountId = type == 'receipt' ? counterparty : affected;

            await txn.insert('ledger_entries', {
              'id': debitId,
              'transaction_id': transactionId,
              'account_id': debitAccountId,
              'side': 'debit',
              'voucher_id': voucherId,
              'amount_minor': amount,
              'currency_code': currency,
              'date': date,
              'created_at': nowStr,
            });

            await txn.insert('ledger_entries', {
              'id': creditId,
              'transaction_id': transactionId,
              'account_id': creditAccountId,
              'side': 'credit',
              'voucher_id': voucherId,
              'amount_minor': amount,
              'currency_code': currency,
              'date': date,
              'created_at': nowStr,
            });
          }
        });
      }
    } catch (e) {
      _debugLog('[AuditLog] ⚠️ Failed to repair ledger entries: $e');
    }
  }
}
