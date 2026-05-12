import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';

// ── Filter ────────────────────────────────────────────────────────────────────

/// Filter settings for the audit log timeline.
class AuditLogFilter {
  final AuditAction? action;
  final AuditSeverity? severity;
  final String? searchQuery;
  final bool showReverted;

  const AuditLogFilter({
    this.action,
    this.severity,
    this.searchQuery,
    this.showReverted = true,
  });

  bool get isActive =>
      action != null ||
      severity != null ||
      (searchQuery?.isNotEmpty ?? false) ||
      !showReverted;

  AuditLogFilter copyWith({
    AuditAction? action,
    AuditSeverity? severity,
    String? searchQuery,
    bool? showReverted,
    bool clearAction = false,
    bool clearSeverity = false,
    bool clearSearch = false,
  }) {
    return AuditLogFilter(
      action: clearAction ? null : (action ?? this.action),
      severity: clearSeverity ? null : (severity ?? this.severity),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
      showReverted: showReverted ?? this.showReverted,
    );
  }

  const AuditLogFilter.empty()
      : action = null,
        severity = null,
        searchQuery = null,
        showReverted = true;
}

// ── State ─────────────────────────────────────────────────────────────────────

/// The complete UI state for the audit log screen.
class AuditLogState {
  /// All entries loaded from the repository (unfiltered).
  final List<AuditEntry> allEntries;

  /// Entries after applying [filter].
  final List<AuditEntry> visibleEntries;

  final AuditLogFilter filter;
  final bool isLoading;
  final bool isExecutingOperation;
  final String? errorMessage;

  /// Entries that would be affected if the currently-selected entry were
  /// independently reverted. Non-null when the impact analysis has run.
  final List<AuditEntry>? impactedEntries;

  const AuditLogState({
    this.allEntries = const [],
    this.visibleEntries = const [],
    this.filter = const AuditLogFilter.empty(),
    this.isLoading = false,
    this.isExecutingOperation = false,
    this.errorMessage,
    this.impactedEntries,
  });

  /// The index of the current HEAD (the newest non-undone entry) in
  /// [visibleEntries], or -1 if all entries are undone.
  int get headIndex => visibleEntries.indexWhere((e) => !e.isUndone);

  bool get isEmpty => allEntries.isEmpty;

  AuditLogState copyWith({
    List<AuditEntry>? allEntries,
    List<AuditEntry>? visibleEntries,
    AuditLogFilter? filter,
    bool? isLoading,
    bool? isExecutingOperation,
    String? errorMessage,
    bool clearError = false,
    List<AuditEntry>? impactedEntries,
    bool clearImpact = false,
  }) {
    return AuditLogState(
      allEntries: allEntries ?? this.allEntries,
      visibleEntries: visibleEntries ?? this.visibleEntries,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isExecutingOperation: isExecutingOperation ?? this.isExecutingOperation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      impactedEntries:
          clearImpact ? null : (impactedEntries ?? this.impactedEntries),
    );
  }
}

// ── Cubit ─────────────────────────────────────────────────────────────────────

class AuditLogCubit extends Cubit<AuditLogState> {
  final AuditLogService _service;

  AuditLogCubit(this._service) : super(const AuditLogState());

  // ── Load ─────────────────────────────────────────────────────────────────────

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final entries = await _service.getQueue();
      if (isClosed) return;

      final filtered = _applyFilter(entries, state.filter);
      emit(state.copyWith(
        allEntries: entries,
        visibleEntries: filtered,
        isLoading: false,
      ));
    } catch (e, st) {
      _handleError('Failed to load audit log', e, st);
    }
  }

  // ── Filter ───────────────────────────────────────────────────────────────────

  void applyFilter(AuditLogFilter filter) {
    final filtered = _applyFilter(state.allEntries, filter);
    emit(state.copyWith(filter: filter, visibleEntries: filtered));
  }

  void clearFilter() {
    emit(state.copyWith(
      filter: const AuditLogFilter.empty(),
      visibleEntries: state.allEntries,
    ));
  }

  // ── Timeline Rollback / Redo ──────────────────────────────────────────────────

  /// Rolls back every active entry **newer than** [id], making [id] the HEAD.
  Future<void> rollbackTo(String id) async {
    emit(state.copyWith(isExecutingOperation: true, clearError: true));
    try {
      await _service.rollbackTo(id);
      await load();
    } catch (e, st) {
      _handleError('Rollback failed', e, st);
    } finally {
      if (!isClosed) emit(state.copyWith(isExecutingOperation: false));
    }
  }

  /// Re-applies undone entries up to [id], making [id] the HEAD.
  Future<void> redoTo(String id) async {
    emit(state.copyWith(isExecutingOperation: true, clearError: true));
    try {
      await _service.redoTo(id);
      await load();
    } catch (e, st) {
      _handleError('Redo failed', e, st);
    } finally {
      if (!isClosed) emit(state.copyWith(isExecutingOperation: false));
    }
  }

  // ── Single-Entry Revert / Redo ────────────────────────────────────────────────

  /// Loads the list of entries that would be affected if [entryId] is
  /// independently reverted, storing results in [state.impactedEntries].
  Future<List<AuditEntry>> loadImpactedEntries(String entryId) async {
    try {
      final affected = await _service.getEntriesAffectedByRevert(entryId);
      if (isClosed) return affected;

      emit(state.copyWith(impactedEntries: affected));
      return affected;
    } catch (e, st) {
      _handleError('Impact analysis failed', e, st);
      return [];
    }
  }

  /// Clears the impact analysis result (called when impact dialog is dismissed).
  void clearImpact() => emit(state.copyWith(clearImpact: true));

  /// Reverts **only** the single entry identified by [id], leaving the rest
  /// of the timeline untouched.
  Future<void> revertSingleEntry(String id) async {
    emit(state.copyWith(
        isExecutingOperation: true, clearError: true, clearImpact: true));
    try {
      await _service.revertSingleEntry(id);
      await load();
    } catch (e, st) {
      _handleError('Single revert failed', e, st);
    } finally {
      if (!isClosed) emit(state.copyWith(isExecutingOperation: false));
    }
  }

  /// Re-applies a single independently reverted entry identified by [id].
  Future<void> redoSingleEntry(String id) async {
    emit(state.copyWith(isExecutingOperation: true, clearError: true));
    try {
      await _service.redoSingleEntry(id);
      await load();
    } catch (e, st) {
      _handleError('Single redo failed', e, st);
    } finally {
      if (!isClosed) emit(state.copyWith(isExecutingOperation: false));
    }
  }

  // ── Internal ─────────────────────────────────────────────────────────────────

  List<AuditEntry> _applyFilter(
      List<AuditEntry> entries, AuditLogFilter filter) {
    var result = entries;

    if (!filter.showReverted) {
      result = result.where((e) => !e.isUndone).toList();
    }

    if (filter.action != null) {
      result = result.where((e) => e.action == filter.action).toList();
    }

    if (filter.severity != null) {
      result = result.where((e) => e.severity == filter.severity).toList();
    }

    final q = filter.searchQuery?.trim().toLowerCase();
    if (q != null && q.isNotEmpty) {
      result = result.where((e) {
        return e.entityType.toLowerCase().contains(q) ||
            e.entityId.toLowerCase().contains(q) ||
            (e.actorId?.toLowerCase().contains(q) ?? false);
      }).toList();
    }

    return result;
  }

  void _handleError(String context, Object error, StackTrace st) {
    if (kDebugMode) debugPrint('[$context] $error\n$st');
    if (!isClosed) {
      emit(state.copyWith(
        isLoading: false,
        isExecutingOperation: false,
        errorMessage: error.toString(),
      ));
    }
  }
}
