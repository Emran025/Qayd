import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/reports/dtos/generate_trial_balance_input.dart';
import 'package:qayd/application/reports/dtos/trial_balance_output.dart';
import 'package:qayd/application/reports/generate_trial_balance_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/pages/reports/trial_balance_state.dart';

class TrialBalanceCubit extends Cubit<TrialBalanceState> {
  TrialBalanceCubit(this._generate) : super(const TrialBalanceInitial());

  final GenerateTrialBalanceUseCase _generate;

  Future<void> load() async {
    emit(const TrialBalanceLoading());
    final result = await _generate(const GenerateTrialBalanceInput());
    result.fold(
      (f) => emit(TrialBalanceFailure(f)),
      (raw) {
        final sorted = List.of(raw.lines)
          ..sort((a, b) => a.accountName.compareTo(b.accountName));
        emit(
          TrialBalanceReady(
            TrialBalanceOutput(
              lines: sorted,
              currencySections: raw.currencySections,
              isOverallBalanced: raw.isOverallBalanced,
            ),
          ),
        );
      },
    );
  }
}
