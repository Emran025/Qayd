import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/create_account_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/core/error/failures.dart';

sealed class AccountCreateState {
  const AccountCreateState();
}

final class AccountCreateIdle extends AccountCreateState {
  const AccountCreateIdle();
}

final class AccountCreateSubmitting extends AccountCreateState {
  const AccountCreateSubmitting();
}

final class AccountCreateSuccess extends AccountCreateState {
  const AccountCreateSuccess();
}

final class AccountCreateFailure extends AccountCreateState {
  const AccountCreateFailure(this.failure);

  final Failure failure;
}

class AccountCreateCubit extends Cubit<AccountCreateState> {
  AccountCreateCubit(this._createAccount) : super(const AccountCreateIdle());

  final CreateAccountUseCase _createAccount;

  Future<void> submit(CreateAccountInput input) async {
    emit(const AccountCreateSubmitting());
    final result = await _createAccount(input);
    result.fold(
      (f) => emit(AccountCreateFailure(f)),
      (_) => emit(const AccountCreateSuccess()),
    );
  }
}
