import 'package:qayd/application/accounts/dtos/deactivate_account_input.dart';
import 'package:qayd/application/accounts/dtos/deactivate_account_output.dart';
import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/governance/governance_write_guard.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/services/balance_calculator.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/money.dart';

class DeactivateAccountUseCase {
  DeactivateAccountUseCase(
    this._accountRepository,
    this._ledgerRepository,
    this._balanceCalculator,
    this._writeGuard,
  );

  final AccountRepository _accountRepository;
  final LedgerRepository _ledgerRepository;
  final BalanceCalculator _balanceCalculator;
  final GovernanceWriteGuard _writeGuard;

  Future<Result<DeactivateAccountOutput>> call(
      DeactivateAccountInput input) async {
    try {
      final gate = await _writeGuard.assertWritesPermitted();
      if (gate.isFailure) {
        return FailureResult(gate.failureOrNull!);
      }
      final loaded =
          await _accountRepository.getById(AccountId(input.accountId));
      if (loaded.isFailure) {
        return FailureResult(loaded.failureOrNull!);
      }
      final account = loaded.valueOrNull!;
      final entriesR = await _ledgerRepository.getEntriesForAccount(account.id);
      if (entriesR.isFailure) {
        return FailureResult(entriesR.failureOrNull!);
      }
      final entries = entriesR.valueOrNull!;
      final perCurrency = _balanceCalculator.signedBalanceMinorUnitsPerCurrency(
        entries: entries,
        accountId: account.id,
        nature: account.nature,
      );
      final hasBalance = perCurrency.values.any((v) => v != 0);
      Money balanceCheck;
      if (hasBalance) {
        final entry = perCurrency.entries.firstWhere((e) => e.value != 0);
        balanceCheck = Money.nonNegative(entry.value.abs(), entry.key);
      } else {
        balanceCheck = Money.zero(
            const CurrencyCode(code: 'SAR', nameAr: 'ريال', symbol: 'ر.س'));
      }
      final deactivated = account.deactivate(balance: balanceCheck);
      final saved = await _accountRepository.save(deactivated);
      return saved.fold(
        (f) => FailureResult(f),
        (_) =>
            Success(DeactivateAccountOutput(accountId: deactivated.id.value)),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
