import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_input.dart';
import 'package:qayd/application/accounts/dtos/list_accounts_output.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/services/balance_calculator.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';

class ListAccountsUseCase {
  ListAccountsUseCase(
    this._accountRepository,
    this._ledgerRepository,
    this._balanceCalculator,
  );

  final AccountRepository _accountRepository;
  final LedgerRepository _ledgerRepository;
  final BalanceCalculator _balanceCalculator;

  Future<Result<ListAccountsOutput>> call(ListAccountsInput input) async {
    try {
      final r = await _accountRepository.getAll(activeOnly: input.activeOnly);
      if (r.isFailure) {
        return FailureResult(r.failureOrNull!);
      }
      var list = r.valueOrNull!;
      if (input.parentAccountId != null) {
        final pid = input.parentAccountId!;
        list = list
            .where((a) => a.parentId?.value == pid)
            .toList(growable: false);
      }

      final summaries = <AccountSummaryDto>[];
      for (final a in list) {
        final entriesR = await _ledgerRepository.getEntriesForAccount(a.id);
        if (entriesR.isFailure) {
          return FailureResult(entriesR.failureOrNull!);
        }
        final entries = entriesR.valueOrNull!;
        final perCurrency = _balanceCalculator.signedBalanceMinorUnitsPerCurrency(
          entries: entries,
          accountId: a.id,
          nature: a.nature,
        );
        final balancesMinorUnits = {
          for (final entry in perCurrency.entries) entry.key.code: entry.value
        };
        summaries.add(
          AccountSummaryDto(
            id: a.id.value,
            name: a.name,
            natureCode: a.nature == AccountNature.debit ? 'debit' : 'credit',
            isActive: a.isActive,
            isRoot: a.isRoot,
            parentId: a.parentId?.value,
            standardClassificationKind: a.classification.standardKind?.name,
            customClassificationName: a.classification.customName,
            balancesMinorUnits: balancesMinorUnits,
          ),
        );
      }

      return Success(ListAccountsOutput(accounts: summaries));
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
