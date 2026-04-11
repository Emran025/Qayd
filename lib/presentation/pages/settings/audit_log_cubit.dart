import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/governance/audit_log_service.dart';
import 'package:qayd/domain/entities/audit_entry.dart';

class AuditLogState {
  final List<AuditEntry> entries;
  final bool isLoading;

  AuditLogState({required this.entries, this.isLoading = false});
}

class AuditLogCubit extends Cubit<AuditLogState> {
  final AuditLogService _service;

  AuditLogCubit(this._service) : super(AuditLogState(entries: []));

  Future<void> load() async {
    emit(AuditLogState(entries: state.entries, isLoading: true));
    final entries = await _service.getQueue();
    emit(AuditLogState(entries: entries, isLoading: false));
  }

  Future<void> rollbackTo(String id) async {
    emit(AuditLogState(entries: state.entries, isLoading: true));
    await _service.rollbackTo(id);
    await load();
  }
}
