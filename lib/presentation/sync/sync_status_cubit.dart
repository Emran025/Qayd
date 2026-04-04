import 'package:flutter_bloc/flutter_bloc.dart';

enum SyncStatus { idle, syncing, connected, decryptionMismatch, error }

class SyncStatusState {
  const SyncStatusState({
    this.status = SyncStatus.idle,
    this.errorMessage,
    this.mismatchedNodeIds = const {},
  });

  final SyncStatus status;
  final String? errorMessage;
  final Set<String> mismatchedNodeIds;

  SyncStatusState copyWith({
    SyncStatus? status,
    String? errorMessage,
    Set<String>? mismatchedNodeIds,
  }) {
    return SyncStatusState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
      mismatchedNodeIds: mismatchedNodeIds ?? this.mismatchedNodeIds,
    );
  }
}

class SyncStatusCubit extends Cubit<SyncStatusState> {
  SyncStatusCubit() : super(const SyncStatusState());

  void setSyncing() => emit(state.copyWith(status: SyncStatus.syncing));
  void setConnected() => emit(state.copyWith(status: SyncStatus.connected));
  void setError(String message) => emit(state.copyWith(status: SyncStatus.error, errorMessage: message));

  void reportDecryptionfailure(String nodeId) {
    final newList = Set<String>.from(state.mismatchedNodeIds)..add(nodeId);
    emit(state.copyWith(
      status: SyncStatus.decryptionMismatch,
      mismatchedNodeIds: newList,
    ));
  }

  void reset() => emit(const SyncStatusState());
}
