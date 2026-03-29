import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_input.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/application/accounts/dtos/get_account_details_output.dart';
import 'package:qayd/application/accounts/get_account_details_use_case.dart';
import 'package:qayd/core/error/failures.dart';

sealed class AccountDetailState {
  const AccountDetailState();
}

final class AccountDetailInitial extends AccountDetailState {
  const AccountDetailInitial();
}

final class AccountDetailLoading extends AccountDetailState {
  const AccountDetailLoading();
}

final class AccountDetailReady extends AccountDetailState {
  const AccountDetailReady(this.data);

  final GetAccountDetailsOutput data;
}

final class AccountDetailFailure extends AccountDetailState {
  const AccountDetailFailure(this.failure);

  final Failure failure;
}

class AccountDetailCubit extends Cubit<AccountDetailState> {
  AccountDetailCubit(this._getDetails) : super(const AccountDetailInitial());

  final GetAccountDetailsUseCase _getDetails;

  Future<void> load(String accountId) async {
    emit(const AccountDetailLoading());
    final result = await _getDetails(
      GetAccountDetailsInput(accountId: accountId),
    );
    result.fold(
      (f) => emit(AccountDetailFailure(f)),
      (data) => emit(AccountDetailReady(data)),
    );
  }
}
