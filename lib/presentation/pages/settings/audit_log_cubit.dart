import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';

// ── State ─────────────────────────────────────────────────────────────────────

/// Filter settings for the audit log timeline.
class AuditLogFilter {
  final AuditAction? action;
  final AuditSeverity? severity;
  final String? searchQuery;

  const AuditLogFilter({this.action, this.severity, this.searchQuery});

  bool get isActive =>
      action != null || severity != null || (searchQuery?.isNotEmpty ?? false);

  AuditLogFilter copyWith({
    AuditAction? action,
    AuditSeverity? severity,
    String? searchQuery,
    bool clearAction = false,
    bool clearSeverity = false,
    bool clearSearch = false,
  }) {
    return AuditLogFilter(
      action: clearAction ? null : (action ?? this.action),
      severity: clearSeverity ? null : (severity ?? this.severity),
      searchQuery: clearSearch ? null : (searchQuery ?? this.searchQuery),
    );
  }

  const AuditLogFilter.empty()
      : action = null,
        severity = null,
        searchQuery = null;
}

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

  const AuditLogState({
    this.allEntries = const [],
    this.visibleEntries = const [],
    this.filter = const AuditLogFilter.empty(),
    this.isLoading = false,
    this.isExecutingOperation = false,
    this.errorMessage,
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
  }) {
    return AuditLogState(
      allEntries: allEntries ?? this.allEntries,
      visibleEntries: visibleEntries ?? this.visibleEntries,
      filter: filter ?? this.filter,
      isLoading: isLoading ?? this.isLoading,
      isExecutingOperation: isExecutingOperation ?? this.isExecutingOperation,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
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

  // ── Undo / Redo ───────────────────────────────────────────────────────────────

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

  // ── Internal ─────────────────────────────────────────────────────────────────

  List<AuditEntry> _applyFilter(
      List<AuditEntry> entries, AuditLogFilter filter) {
    var result = entries;

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
