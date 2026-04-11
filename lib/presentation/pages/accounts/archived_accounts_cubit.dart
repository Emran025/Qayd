import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_output.dart';
import 'package:qayd/application/accounts/list_archived_accounts_use_case.dart';
import 'package:qayd/application/accounts/restore_account_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';

sealed class ArchivedAccountsState {}

final class ArchivedAccountsLoading extends ArchivedAccountsState {}

final class ArchivedAccountsReady extends ArchivedAccountsState {
  ArchivedAccountsReady(this.data);
  final ListAccountsOutput data;
}

final class ArchivedAccountsFailure extends ArchivedAccountsState {
  ArchivedAccountsFailure(this.failure);
  final Failure failure;
}

class ArchivedAccountsCubit extends Cubit<ArchivedAccountsState> {
  ArchivedAccountsCubit({
    required this.listArchivedAccounts,
    required this.restoreAccount,
  }) : super(ArchivedAccountsLoading());

  final ListArchivedAccountsUseCase listArchivedAccounts;
  final RestoreAccountUseCase restoreAccount;

  Future<void> load() async {
    emit(ArchivedAccountsLoading());
    final result = await listArchivedAccounts();
    result.fold(
      (failure) => emit(ArchivedAccountsFailure(failure)),
      (data) => emit(ArchivedAccountsReady(data)),
    );
  }

  Future<void> restore(String accountId, void Function(String) onError,
      void Function() onSuccess) async {
    final result = await restoreAccount(accountId);
    result.fold(
      (failure) => onError(failure.messageAr),
      (_) {
        onSuccess();
        load(); // Refresh list after parsing
      },
    );
  }
}
