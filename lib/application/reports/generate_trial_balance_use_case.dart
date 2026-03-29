import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/application/reports/dtos/generate_trial_balance_input.dart';
import 'package:qayd/application/reports/dtos/trial_balance_line_dto.dart';
import 'package:qayd/application/reports/dtos/trial_balance_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/services/trial_balance_generator.dart';

class GenerateTrialBalanceUseCase {
  GenerateTrialBalanceUseCase(
    this._accountRepository,
    this._ledgerRepository,
    this._trialBalanceGenerator,
  );

  final AccountRepository _accountRepository;
  final LedgerRepository _ledgerRepository;
  final TrialBalanceGenerator _trialBalanceGenerator;

  Future<Result<TrialBalanceOutput>> call(GenerateTrialBalanceInput input) async {
    try {
      if (input.fromDate != null &&
          input.toDate != null &&
          input.fromDate!.isAfter(input.toDate!)) {
        return FailureResult(
          ValidationFailure(
            messageAr: 'نطاق التواريخ غير صالح.',
            code: 'trial_balance_date_range',
          ),
        );
      }

      final accountsR = await _accountRepository.getAll();
      if (accountsR.isFailure) {
        return FailureResult(accountsR.failureOrNull!);
      }
      final entriesR = await _ledgerRepository.getAllEntries();
      if (entriesR.isFailure) {
        return FailureResult(entriesR.failureOrNull!);
      }
      final accounts = accountsR.valueOrNull!;
      var entries = entriesR.valueOrNull!;
      entries = entries
          .where((e) => _inDateRange(e.date, input.fromDate, input.toDate))
          .toList(growable: false);

      final report = _trialBalanceGenerator.build(
        accounts: accounts,
        allEntries: entries,
      );

      final nameById = {
        for (final a in accounts) a.id.value: a.name,
      };

      return Success(
        TrialBalanceOutput(
          lines: report.lines
              .map(
                (l) => TrialBalanceLineDto(
                  accountId: l.accountId.value,
                  accountName:
                      nameById[l.accountId.value] ?? l.accountId.value,
                  currencyCode: l.currency.code,
                  currencySymbol: l.currency.symbol,
                  currencyDigits: l.currency.fractionalDigits,
                  debitMinorUnits: l.debitMinorUnits,
                  creditMinorUnits: l.creditMinorUnits,
                ),
              )
              .toList(growable: false),
          currencySections: {
            for (final entry in report.currencySections.entries)
              entry.key.code: TrialBalanceCurrencySectionDto(
                currencyCode: entry.key.code,
                currencySymbol: entry.key.symbol,
                currencyDigits: entry.key.fractionalDigits,
                totalDebitMinorUnits: entry.value.totalDebitMinorUnits,
                totalCreditMinorUnits: entry.value.totalCreditMinorUnits,
                isBalanced: entry.value.isBalanced,
                imbalanceMinorUnits: entry.value.imbalanceMinorUnits,
              ),
          },
          isOverallBalanced: report.isBalanced,
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }

  bool _inDateRange(DateTime entry, DateTime? from, DateTime? to) {
    final day = DateTime(entry.year, entry.month, entry.day);
    if (from != null) {
      final f = DateTime(from.year, from.month, from.day);
      if (day.isBefore(f)) return false;
    }
    if (to != null) {
      final t = DateTime(to.year, to.month, to.day);
      if (day.isAfter(t)) return false;
    }
    return true;
  }
}
