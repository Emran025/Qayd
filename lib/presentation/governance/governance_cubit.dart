import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/governance/check_governance_status_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/governance/dtos/check_governance_status_input.dart';
import 'package:qayd/application/governance/dtos/submit_activation_input.dart';
import 'package:qayd/application/governance/submit_activation_use_case.dart';
import 'package:qayd/presentation/governance/governance_ui_state.dart';

class GovernanceCubit extends Cubit<GovernanceUiState> {
  GovernanceCubit(
    this._checkGovernance,
    this._submitActivation,
  ) : super(const GovernanceUiState());

  final CheckGovernanceStatusUseCase _checkGovernance;
  final SubmitActivationUseCase _submitActivation;

  void scheduleBackgroundVerification() {
    Future<void>.microtask(verifyRemoteStatus);
  }

  Future<void> verifyRemoteStatus() async {
    emit(state.copyWith(refreshInFlight: true, clearLastError: true));
    final result = await _checkGovernance(
      const CheckGovernanceStatusInput(forceRefresh: true),
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (f) => emit(
        state.copyWith(
          refreshInFlight: false,
          lastErrorAr: f.messageAr,
        ),
      ),
      (s) => emit(
        state.copyWith(
          refreshInFlight: false,
          status: s,
          clearLastError: true,
        ),
      ),
    );
  }

  Future<void> submitActivation({
    required String organizationId,
    required String licenseKey,
  }) async {
    emit(state.copyWith(refreshInFlight: true, clearLastError: true));
    final result = await _submitActivation(
      SubmitActivationInput(
        organizationId: organizationId,
        licenseKey: licenseKey,
      ),
    );
    if (isClosed) {
      return;
    }
    result.fold(
      (f) => emit(
        state.copyWith(
          refreshInFlight: false,
          lastErrorAr: f.messageAr,
        ),
      ),
      (_) => verifyRemoteStatus(),
    );
  }
}
