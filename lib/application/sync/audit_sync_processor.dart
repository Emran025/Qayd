import 'package:flutter/foundation.dart';
import 'package:qayd/domain/entities/audit_entry.dart';
import 'package:qayd/domain/repositories/audit_log_repository.dart';
import 'package:qayd/application/governance/audit_log_service.dart';

class AuditSyncProcessor {
  const AuditSyncProcessor({
    required this.auditLogRepository,
    this.auditLogService,
  });

  final AuditLogRepository auditLogRepository;
  final AuditLogService? auditLogService;

  Future<void> processBatch(List<Map<String, dynamic>> entryMaps) async {
    final existingIds =
        (await auditLogRepository.listAll()).map((e) => e.id).toSet();

    // Parse and deduplicate all entries.
    final entries = <AuditEntry>[];
    for (final map in entryMaps) {
      final rawEntry = AuditEntry.fromMap(map);
      final entry = rawEntry.actorId == null
          ? rawEntry.copyWith(actorId: 'sync:remote')
          : rawEntry;
      if (!existingIds.contains(entry.id)) {
        entries.add(entry);
      }
    }

    if (entries.isEmpty) return;

    // Topologically sort CREATE entries so parent rows are inserted before
    // children. Non-CREATE entries (UPDATE, DELETE, REVERT) keep their
    // original order and are appended after all CREATEs.
    final sorted = _topologicalSort(entries);

    // First pass: apply all entries in topological order.
    // Collect any that fail due to FK constraints for a retry pass.
    final deferred = <AuditEntry>[];
    for (final entry in sorted) {
      final ok = await _tryApply(entry, existingIds);
      if (!ok) {
        deferred.add(entry);
      }
    }

    // Second pass: retry deferred entries. After the first pass, parent
    // rows that were later in the batch are now present. We retry up to
    // 3 rounds to handle multi-level dependency chains.
    var retryQueue = deferred;
    for (var round = 0; round < 3 && retryQueue.isNotEmpty; round++) {
      final stillFailing = <AuditEntry>[];
      for (final entry in retryQueue) {
        final ok = await _tryApply(entry, existingIds);
        if (!ok) {
          stillFailing.add(entry);
        }
      }
      if (stillFailing.length == retryQueue.length) {
        // No progress — stop retrying to avoid infinite loops.
        break;
      }
      retryQueue = stillFailing;
    }

    if (retryQueue.isNotEmpty) {
      debugPrint(
        '[AuditSyncProcessor] ⚠️ ${retryQueue.length} entries could not be '
        'applied after retry: ${retryQueue.map((e) => '${e.entityType}/${e.entityId}').join(', ')}',
      );
    }
  }

  /// Attempts to replay and save a single entry.
  /// Returns `true` on success, `false` on failure (FK constraint, etc.).
  Future<bool> _tryApply(AuditEntry entry, Set<String> existingIds) async {
    try {
      await auditLogService?.replaySyncedEntry(entry);
      await auditLogRepository.save(entry);
      existingIds.add(entry.id);
      return true;
    } catch (e) {
      debugPrint(
        '[AuditSyncProcessor] ⚠️ Failed to apply ${entry.action.label} '
        '${entry.entityType}/${entry.entityId}: $e',
      );
      return false;
    }
  }

  /// Topologically sorts entries so that CREATE entries whose `_parent`
  /// data references another entity in the batch are placed after that
  /// dependency. Non-CREATE entries are appended in original order.
  List<AuditEntry> _topologicalSort(List<AuditEntry> entries) {
    // Separate CREATEs from everything else.
    final creates = <AuditEntry>[];
    final others = <AuditEntry>[];
    for (final e in entries) {
      if (e.action == AuditAction.create) {
        creates.add(e);
      } else {
        others.add(e);
      }
    }

    if (creates.length <= 1) {
      return [...creates, ...others];
    }

    // Build a set of entity IDs present in this batch (for CREATEs only).
    final batchEntityIds = <String>{};
    for (final e in creates) {
      batchEntityIds.add(e.entityId);
    }

    // Build adjacency: entityId → set of entityIds it depends on.
    // We extract FK references from the _parent snapshot data.
    final deps = <String, Set<String>>{};
    for (final e in creates) {
      deps[e.entityId] = _extractDependencies(e, batchEntityIds);
    }

    // Kahn's algorithm for topological sort.
    final inDegree = <String, int>{};
    final adjList = <String, List<String>>{}; // dependency → dependents
    for (final e in creates) {
      inDegree.putIfAbsent(e.entityId, () => 0);
      for (final dep in deps[e.entityId]!) {
        adjList.putIfAbsent(dep, () => []).add(e.entityId);
        inDegree[e.entityId] = (inDegree[e.entityId] ?? 0) + 1;
      }
    }

    final queue = <String>[];
    for (final e in creates) {
      if ((inDegree[e.entityId] ?? 0) == 0) {
        queue.add(e.entityId);
      }
    }

    final sortedIds = <String>[];
    while (queue.isNotEmpty) {
      final current = queue.removeAt(0);
      sortedIds.add(current);
      for (final dependent in adjList[current] ?? <String>[]) {
        inDegree[dependent] = (inDegree[dependent] ?? 1) - 1;
        if (inDegree[dependent] == 0) {
          queue.add(dependent);
        }
      }
    }

    // Any remaining entries not in sortedIds (cycles) — append at end.
    final sortedSet = sortedIds.toSet();
    for (final e in creates) {
      if (!sortedSet.contains(e.entityId)) {
        sortedIds.add(e.entityId);
      }
    }

    // Map entityId → entry for lookup.
    final entryById = <String, AuditEntry>{};
    for (final e in creates) {
      entryById[e.entityId] = e;
    }

    final result = <AuditEntry>[];
    for (final id in sortedIds) {
      final entry = entryById[id];
      if (entry != null) result.add(entry);
    }

    // Append non-CREATE entries after all CREATEs.
    result.addAll(others);
    return result;
  }

  /// Extracts entity IDs that [entry] depends on by scanning the `_parent`
  /// snapshot for columns whose values match entity IDs in [batchEntityIds].
  Set<String> _extractDependencies(
      AuditEntry entry, Set<String> batchEntityIds) {
    final result = <String>{};
    final parentData = entry.oldData?['_parent'] as Map?;
    if (parentData == null) return result;

    for (final value in parentData.values) {
      if (value is String &&
          value != entry.entityId &&
          batchEntityIds.contains(value)) {
        result.add(value);
      }
    }
    return result;
  }
}
