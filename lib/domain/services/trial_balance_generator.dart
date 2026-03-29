import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/services/balance_calculator.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/trial_balance_line.dart';
import 'package:qayd/domain/value_objects/trial_balance_report.dart';

/// Builds a per-currency trial balance from accounts and all ledger lines.
final class TrialBalanceGenerator {
  const TrialBalanceGenerator({
    BalanceCalculator balanceCalculator = const BalanceCalculator(),
  }) : _balanceCalculator = balanceCalculator;

  final BalanceCalculator _balanceCalculator;

  TrialBalanceReport build({
    required List<Account> accounts,
    required List<LedgerEntry> allEntries,
  }) {
    final lines = <TrialBalanceLine>[];
    for (final account in accounts) {
      final perCurrency = _balanceCalculator.signedBalanceMinorUnitsPerCurrency(
        entries: allEntries,
        accountId: account.id,
        nature: account.nature,
      );
      for (final entry in perCurrency.entries) {
        lines.add(
          TrialBalanceLine.fromSignedBalance(
            accountId: account.id,
            accountNature: account.nature,
            currency: entry.key,
            signedMinorUnits: entry.value,
          ),
        );
      }
    }

    // Build per-currency sections.
    final sectionDebits = <CurrencyCode, int>{};
    final sectionCredits = <CurrencyCode, int>{};
    for (final line in lines) {
      sectionDebits[line.currency] =
          (sectionDebits[line.currency] ?? 0) + line.debitMinorUnits;
      sectionCredits[line.currency] =
          (sectionCredits[line.currency] ?? 0) + line.creditMinorUnits;
    }
    final allCurrencies = {...sectionDebits.keys, ...sectionCredits.keys};
    final sections = <CurrencyCode, TrialBalanceCurrencySection>{};
    for (final c in allCurrencies) {
      final d = sectionDebits[c] ?? 0;
      final cr = sectionCredits[c] ?? 0;
      final imbalance = d - cr;
      sections[c] = TrialBalanceCurrencySection(
        currency: c,
        totalDebitMinorUnits: d,
        totalCreditMinorUnits: cr,
        isBalanced: imbalance == 0,
        imbalanceMinorUnits: imbalance,
      );
    }

    return TrialBalanceReport(
      lines: List.unmodifiable(lines),
      currencySections: Map.unmodifiable(sections),
    );
  }
}
