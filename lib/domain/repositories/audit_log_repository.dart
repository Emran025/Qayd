import 'package:qayd/domain/entities/audit_entry.dart';

/// Contract for persisting and querying the immutable audit trail.
abstract interface class AuditLogRepository {
  // ── Write operations ────────────────────────────────────────────────────────

  /// Persists a new [AuditEntry]. Throws on failure.
  Future<void> save(AuditEntry entry);

  /// Updates an existing entry (e.g., to flip [AuditEntry.isUndone] or
  /// update the enriched [AuditEntry.oldData] after a backup capture).
  Future<void> update(AuditEntry entry);

  // ── Read operations ─────────────────────────────────────────────────────────

  /// Returns all entries ordered newest-first (for undo/redo stack traversal).
  Future<List<AuditEntry>> listAll();

  /// Returns all entries for a given [batchId], ordered newest-first.
  Future<List<AuditEntry>> getByBatchId(String batchId);

  /// Returns entries for a specific entity, ordered newest-first.
  Future<List<AuditEntry>> getByEntity(String entityType, String entityId);

  /// Returns entries that are currently active (not undone), ordered newest-first.
  Future<List<AuditEntry>> listActive();

  /// Returns the single newest active entry (the current HEAD), or `null`
  /// if the audit trail is empty or every entry is undone.
  Future<AuditEntry?> getLatest();

  /// Returns the total count of entries (for display in the UI badge).
  Future<int> countAll();

  // ── Cleanup operations ──────────────────────────────────────────────────────

  /// Deletes all audit entries.
  Future<void> clear();

  /// Deletes all entries created **after** [timestamp].
  Future<void> deleteAfter(DateTime timestamp);

  /// Deletes all **undone** entries created **after** [timestamp].
  ///
  /// Called by [AuditLogService._pruneRedoBranch] when the user performs a
  /// new mutation after having undone some steps — effectively discarding the
  /// orphaned redo branch.
  Future<void> deleteUndoneAfter(DateTime timestamp);
}
