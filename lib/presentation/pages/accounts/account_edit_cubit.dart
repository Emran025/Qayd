import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/update_account_use_case.dart';
import 'package:qayd/application/accounts/dtos/update_account_input.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';

// ── States ──────────────────────────────────────────────────────────────────

sealed class AccountEditState {
  const AccountEditState();
}

final class AccountEditIdle extends AccountEditState {
  const AccountEditIdle();
}

final class AccountEditSubmitting extends AccountEditState {
  const AccountEditSubmitting();
}

final class AccountEditSuccess extends AccountEditState {
  const AccountEditSuccess();
}

final class AccountEditFailure extends AccountEditState {
  const AccountEditFailure(this.failure);

  final Failure failure;
}

// ── Cubit ────────────────────────────────────────────────────────────────────

class AccountEditCubit extends Cubit<AccountEditState> {
  AccountEditCubit(this._updateAccount) : super(const AccountEditIdle());

  final UpdateAccountUseCase _updateAccount;

  Future<void> submit(UpdateAccountInput input) async {
    emit(const AccountEditSubmitting());
    final result = await _updateAccount(input);
    result.fold(
      (f) => emit(AccountEditFailure(f)),
      (_) => emit(const AccountEditSuccess()),
    );
  }
}
