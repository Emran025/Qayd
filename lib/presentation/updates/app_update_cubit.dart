import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/app_updates/check_app_update_use_case.dart';
import 'package:qayd/application/app_updates/install_app_update_use_case.dart';
import 'package:qayd/domain/entities/app_update_snapshot.dart';

final class AppUpdateState {
  const AppUpdateState({
    this.status = AppUpdateStatus.unavailable,
    this.isChecking = false,
    this.isInstalling = false,
    this.currentPatchNumber,
    this.errorMessage,
  });

  final AppUpdateStatus status;
  final bool isChecking;
  final bool isInstalling;
  final int? currentPatchNumber;
  final String? errorMessage;

  bool get shouldShowBanner =>
      status == AppUpdateStatus.updateAvailable ||
      status == AppUpdateStatus.restartRequired;

  AppUpdateState copyWith({
    AppUpdateStatus? status,
    bool? isChecking,
    bool? isInstalling,
    int? currentPatchNumber,
    String? errorMessage,
    bool clearError = false,
  }) {
    return AppUpdateState(
      status: status ?? this.status,
      isChecking: isChecking ?? this.isChecking,
      isInstalling: isInstalling ?? this.isInstalling,
      currentPatchNumber: currentPatchNumber ?? this.currentPatchNumber,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
    );
  }
}

final class AppUpdateCubit extends Cubit<AppUpdateState> {
  AppUpdateCubit({
    required CheckAppUpdateUseCase checkUpdate,
    required InstallAppUpdateUseCase installUpdate,
  })  : _checkUpdate = checkUpdate,
        _installUpdate = installUpdate,
        super(const AppUpdateState());

  final CheckAppUpdateUseCase _checkUpdate;
  final InstallAppUpdateUseCase _installUpdate;

  Future<void> check() async {
    if (state.isChecking || state.isInstalling) return;
    emit(state.copyWith(isChecking: true, clearError: true));
    final result = await _checkUpdate();
    if (isClosed) return;
    final snapshot = result.valueOrNull;
    if (snapshot == null) {
      emit(state.copyWith(
        isChecking: false,
        errorMessage: result.failureOrNull?.messageAr,
      ));
      return;
    }
    emit(AppUpdateState(
      status: snapshot.status,
      isChecking: false,
      currentPatchNumber: snapshot.currentPatchNumber,
      errorMessage: snapshot.message,
    ));
  }

  Future<void> install() async {
    if (state.isInstalling || state.status != AppUpdateStatus.updateAvailable) {
      return;
    }
    emit(state.copyWith(isInstalling: true, clearError: true));
    final result = await _installUpdate();
    if (isClosed) return;
    if (result.isFailure) {
      emit(state.copyWith(
        isInstalling: false,
        errorMessage: result.failureOrNull?.messageAr,
      ));
      return;
    }
    emit(state.copyWith(
      status: AppUpdateStatus.restartRequired,
      isInstalling: false,
      clearError: true,
    ));
  }
}
