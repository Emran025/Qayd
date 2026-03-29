import 'package:qayd/application/reports/dtos/trial_balance_output.dart';
import 'package:qayd/core/error/failures.dart';

sealed class TrialBalanceState {
  const TrialBalanceState();
}

final class TrialBalanceInitial extends TrialBalanceState {
  const TrialBalanceInitial();
}

final class TrialBalanceLoading extends TrialBalanceState {
  const TrialBalanceLoading();
}

final class TrialBalanceReady extends TrialBalanceState {
  const TrialBalanceReady(this.output);

  final TrialBalanceOutput output;
}

final class TrialBalanceFailure extends TrialBalanceState {
  const TrialBalanceFailure(this.failure);

  final Failure failure;
}
