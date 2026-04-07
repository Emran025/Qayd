import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/account_nature.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/entry_side.dart';

/// Computes per-currency signed balances from ledger lines using account normal balance rules.
class BalanceCalculator {
  const BalanceCalculator();

  /// Returns a per-currency map of signed balance in minor units.
  ///
  /// For debit-nature accounts: Balance[C] = debits_in_C − credits_in_C
  /// For credit-nature accounts: Balance[C] = credits_in_C − debits_in_C
  Map<CurrencyCode, int> signedBalanceMinorUnitsPerCurrency({
    required Iterable<LedgerEntry> entries,
    required AccountId accountId,
    required AccountNature nature,
  }) {
    final debits = <CurrencyCode, int>{};
    final credits = <CurrencyCode, int>{};
    for (final entry in entries) {
      if (entry.accountId != accountId) continue;
      final c = entry.currency;
      switch (entry.side) {
        case EntrySide.debit:
          debits[c] = (debits[c] ?? 0) + entry.amount.minorUnits;
        case EntrySide.credit:
          credits[c] = (credits[c] ?? 0) + entry.amount.minorUnits;
      }
    }
    final allCurrencies = {...debits.keys, ...credits.keys};
    final result = <CurrencyCode, int>{};
    for (final c in allCurrencies) {
      final d = debits[c] ?? 0;
      final cr = credits[c] ?? 0;
      result[c] = nature == AccountNature.debit ? d - cr : cr - d;
    }
    return result;
  }

  /// Legacy convenience: signed total in minor units for a **single currency**.
  ///
  /// Returns the sum across all currencies (backward-compatible for use cases
  /// that don't need per-currency breakdown, e.g. deactivation zero-check).
  int signedBalanceMinorUnits({
    required Iterable<LedgerEntry> entries,
    required AccountId accountId,
    required AccountNature nature,
  }) {
    final perCurrency = signedBalanceMinorUnitsPerCurrency(
      entries: entries,
      accountId: accountId,
      nature: nature,
    );
    // Sum across currencies — used only for zero-check (all currencies must be zero).
    return perCurrency.values.fold(0, (sum, v) => sum + v);
  }
}
