import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/trial_balance_line.dart';
import 'package:qayd/domain/value_objects/trial_balance_report.dart';

/// Advanced generator for hierarchical trial balances with Opening,
/// Movement, and Closing balance columns.
final class TrialBalanceGenerator {
  const TrialBalanceGenerator();

  TrialBalanceReport build({
    required String title,
    required String companyName,
    required DateRange dateRange,
    required List<Account> accounts,
    required List<LedgerEntry> allEntries,
  }) {
    // 1. Prepare maps for faster lookups.
    final accountMap = {for (final a in accounts) a.id: a};

    // 2. Map direct activity for each account/currency in a single pass.
    final rawActivity = <dynamic, Map<CurrencyCode, _AccountActivity>>{};

    for (final e in allEntries) {
      // Check if entry is within or before the period.
      final isBefore = e.createdAt.isBefore(dateRange.start);
      final isInPeriod = !isBefore && dateRange.contains(e.createdAt);

      if (!isBefore && !isInPeriod) continue;

      final accMap = rawActivity.putIfAbsent(e.accountId, () => {});
      final activity = accMap.putIfAbsent(e.currency, () => _AccountActivity());

      if (isBefore) {
        if (e.isDebit) {
          activity.openingDebit += e.amount.minorUnits;
        } else {
          activity.openingCredit += e.amount.minorUnits;
        }
      } else {
        if (e.isDebit) {
          activity.periodDebit += e.amount.minorUnits;
        } else {
          activity.periodCredit += e.amount.minorUnits;
        }
      }
    }

    // 3. Roll up balances from children to parents.
    // We sort accounts by depth (deepest first) to ensure totals bubble up.
    final sortedAccounts = _sortAccountsByDepth(accounts);
    final rolledActivity = <dynamic, Map<CurrencyCode, _AccountActivity>>{};

    // Initialize rolledActivity with existing data.
    rawActivity.forEach((accId, currencies) {
      rolledActivity[accId] = currencies.map((c, a) => MapEntry(c, a.clone()));
    });

    for (final account in sortedAccounts) {
      if (account.parentId == null) continue;

      final currentAccActivity = rolledActivity[account.id];
      if (currentAccActivity == null) continue;

      final parentAccActivityMap =
          rolledActivity.putIfAbsent(account.parentId!, () => {});

      currentAccActivity.forEach((currency, activity) {
        final parentActivity = parentAccActivityMap.putIfAbsent(
            currency, () => _AccountActivity());
        parentActivity.add(activity);
      });
    }

    // 4. Build TrialBalanceLines efficiently.
    final lines = <TrialBalanceLine>[];
    final parentIdSet = {
      for (final a in accounts)
        if (a.parentId != null) a.parentId!
    };

    for (final account in accounts) {
      final activityMap = rolledActivity[account.id] ?? {};
      final isParent = parentIdSet.contains(account.id);

      if (activityMap.isEmpty && !isParent) continue;

      for (final entry in activityMap.entries) {
        final currency = entry.key;
        final a = entry.value;

        lines.add(TrialBalanceLine(
          accountId: account.id,
          accountCode: account.metadata['code']?.toString() ?? '',
          accountName: account.name,
          accountLevel: _calculateLevel(account, accountMap),
          isParent: isParent,
          currency: currency,
          openingDebitMinorUnits: a.openingDebit,
          openingCreditMinorUnits: a.openingCredit,
          periodDebitMinorUnits: a.periodDebit,
          periodCreditMinorUnits: a.periodCredit,
          closingDebitMinorUnits: a.closingDebit,
          closingCreditMinorUnits: a.closingCredit,
        ));
      }
    }

    // 5. Build Currency Sections (Totals from Root accounts).
    final sections = <CurrencyCode, TrialBalanceCurrencySection>{};
    for (final line in lines) {
      final account = accountMap[line.accountId];
      if (account == null || account.parentId != null) continue;

      final s = sections.putIfAbsent(
          line.currency,
          () => TrialBalanceCurrencySection(
                currency: line.currency,
                openingDebitMinorUnits: 0,
                openingCreditMinorUnits: 0,
                periodDebitMinorUnits: 0,
                periodCreditMinorUnits: 0,
                closingDebitMinorUnits: 0,
                closingCreditMinorUnits: 0,
              ));

      sections[line.currency] = TrialBalanceCurrencySection(
        currency: s.currency,
        openingDebitMinorUnits:
            s.openingDebitMinorUnits + line.openingDebitMinorUnits,
        openingCreditMinorUnits:
            s.openingCreditMinorUnits + line.openingCreditMinorUnits,
        periodDebitMinorUnits:
            s.periodDebitMinorUnits + line.periodDebitMinorUnits,
        periodCreditMinorUnits:
            s.periodCreditMinorUnits + line.periodCreditMinorUnits,
        closingDebitMinorUnits:
            s.closingDebitMinorUnits + line.closingDebitMinorUnits,
        closingCreditMinorUnits:
            s.closingCreditMinorUnits + line.closingCreditMinorUnits,
      );
    }

    return TrialBalanceReport(
      title: title,
      companyName: companyName,
      dateRange: dateRange,
      lines: List.unmodifiable(lines),
      currencySections: Map.unmodifiable(sections),
    );
  }

  List<Account> _sortAccountsByDepth(List<Account> accounts) {
    final accountMap = {for (final a in accounts) a.id: a};
    final depths = <dynamic, int>{};

    int getDepth(Account a) {
      if (depths.containsKey(a.id)) return depths[a.id]!;
      if (a.parentId == null) return depths[a.id] = 0;
      final parent = accountMap[a.parentId];
      if (parent == null) return depths[a.id] = 0;
      return depths[a.id] = 1 + getDepth(parent);
    }

    for (final a in accounts) {
      getDepth(a);
    }

    final sorted = List<Account>.from(accounts);
    sorted.sort((a, b) => depths[b.id]!.compareTo(depths[a.id]!));
    return sorted;
  }

  int _calculateLevel(Account account, Map<dynamic, Account> accountMap) {
    int level = 0;
    Account? current = account;
    while (current?.parentId != null) {
      current = accountMap[current!.parentId];
      level++;
    }
    return level;
  }
}

class _AccountActivity {
  int openingDebit = 0;
  int openingCredit = 0;
  int periodDebit = 0;
  int periodCredit = 0;

  int get closingDebit => openingDebit + periodDebit;
  int get closingCredit => openingCredit + periodCredit;

  void add(_AccountActivity other) {
    openingDebit += other.openingDebit;
    openingCredit += other.openingCredit;
    periodDebit += other.periodDebit;
    periodCredit += other.periodCredit;
  }

  _AccountActivity clone() {
    return _AccountActivity()
      ..openingDebit = openingDebit
      ..openingCredit = openingCredit
      ..periodDebit = periodDebit
      ..periodCredit = periodCredit;
  }
}
