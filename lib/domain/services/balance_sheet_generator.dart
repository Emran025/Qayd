import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/value_objects/account_classification.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

/// One line in a balance sheet report.
final class BalanceSheetLine {
  const BalanceSheetLine({
    required this.accountId,
    required this.accountCode,
    required this.accountName,
    required this.parentId,
    required this.level,
    required this.isParent,
    required this.currency,
    required this.balanceMinorUnits,
    required this.classification,
  });

  final String accountId;
  final String? parentId;
  final String accountCode;
  final String accountName;
  final int level;
  final bool isParent;
  final CurrencyCode currency;
  final int balanceMinorUnits;
  final AccountClassification classification;
}

/// Specialized generator for Balance Sheet reports.
///
/// Builds a hierarchical balance sheet from the chart of accounts and
/// all ledger entries up to (inclusive) the requested [atDate].
/// Accounts are grouped by classification (Assets → Liabilities → Equity)
/// and ordered by account code within each group.
final class BalanceSheetGenerator {
  const BalanceSheetGenerator();

  List<BalanceSheetLine> build({
    required DateTime atDate,
    required List<Account> accounts,
    required List<LedgerEntry> allEntries,
  }) {
    // ── 1. Filter entries up to (inclusive) the target date ──────────────
    final cutoff = DateTime(atDate.year, atDate.month, atDate.day, 23, 59, 59);
    final entriesBefore = allEntries.where(
      (e) => !e.createdAt.isAfter(cutoff),
    );
    final accountMap = {for (final a in accounts) a.id: a};

    // ── 2. Calculate raw balance per account/currency ────────────────────
    final rawBalances = <AccountId, Map<CurrencyCode, int>>{};
    for (final e in entriesBefore) {
      final acc = accountMap[e.accountId];
      if (acc == null) continue;

      final accMap = rawBalances.putIfAbsent(e.accountId, () => {});
      final current = accMap[e.currency] ?? 0;
      accMap[e.currency] =
          current + (e.isDebit ? e.amount.minorUnits : -e.amount.minorUnits);
    }

    // ── 3. Hierarchical Roll-up (children → parents) ────────────────────
    final sortedByDepth = _sortAccountsByDepth(accounts);
    final rolledBalances = <AccountId, Map<CurrencyCode, int>>{};
    rawBalances.forEach(
      (id, map) => rolledBalances[id] = Map<CurrencyCode, int>.from(map),
    );

    for (final account in sortedByDepth) {
      if (account.parentId == null) continue;
      final currentBalances = rolledBalances[account.id];
      if (currentBalances == null) continue;

      final parentBalances =
          rolledBalances.putIfAbsent(account.parentId!, () => {});
      currentBalances.forEach((currency, balance) {
        parentBalances[currency] = (parentBalances[currency] ?? 0) + balance;
      });
    }

    // ── 4. Build output lines ───────────────────────────────────────────
    final lines = <BalanceSheetLine>[];
    for (final account in accounts) {
      final balanceMap = rolledBalances[account.id] ?? {};
      final isParent = accounts.any((a) => a.parentId == account.id);

      // Skip leaf accounts with zero balance.
      if (balanceMap.isEmpty && !isParent) continue;

      for (final entry in balanceMap.entries) {
        // Skip exactly zero balance to keep reports clean
        if (entry.value == 0 && !isParent) continue;

        lines.add(BalanceSheetLine(
          accountId: account.id.value,
          parentId: account.parentId?.value,
          accountCode: account.metadata['code']?.toString() ?? '',
          accountName: account.name,
          level: _calculateLevel(account, accountMap),
          isParent: isParent,
          currency: entry.key,
          balanceMinorUnits: entry.value,
          classification: account.classification,
        ));
      }
    }

    // ── 5. Sort: classification order → account code ─────────────────────
    lines.sort((a, b) {
      final aIdx = _classificationOrder(a.classification);
      final bIdx = _classificationOrder(b.classification);
      final classOrder = aIdx.compareTo(bIdx);
      if (classOrder != 0) return classOrder;
      return a.accountCode.compareTo(b.accountCode);
    });

    return lines;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  /// Returns a stable ordering index for each classification bucket
  /// that matches the accounting equation: Assets → Liabilities → Equity.
  int _classificationOrder(AccountClassification c) {
    if (c == AccountClassification.liquidAssets) return 0;
    if (c == AccountClassification.receivables) return 1;
    if (c == AccountClassification.fixedProfitableAssets) return 2;
    if (c == AccountClassification.fixedDepreciableAssets) return 3;
    if (c == AccountClassification.payables) return 10;
    if (c == AccountClassification.settlements) return 11;
    if (c == AccountClassification.clearingRemittances) return 12;
    if (c == AccountClassification.personalExpenses) return 20;
    if (c == AccountClassification.personalRevenues) return 21;
    if (c == AccountClassification.remittanceFees) return 22;
    return 99;
  }

  List<Account> _sortAccountsByDepth(List<Account> accounts) {
    final accountMap = <AccountId, Account>{
      for (final a in accounts) a.id: a,
    };
    final depths = <AccountId, int>{};

    int getDepth(Account a) {
      if (depths.containsKey(a.id)) return depths[a.id]!;
      if (a.parentId == null) return depths[a.id] = 0;
      final parent = accountMap[a.parentId];
      return depths[a.id] = 1 + (parent == null ? -1 : getDepth(parent));
    }

    for (final a in accounts) {
      getDepth(a);
    }
    final sorted = List<Account>.from(accounts);
    sorted.sort((a, b) => depths[b.id]!.compareTo(depths[a.id]!));
    return sorted;
  }

  int _calculateLevel(Account account, Map<AccountId, Account> accountMap) {
    int level = 0;
    Account? current = account;
    while (current?.parentId != null) {
      current = accountMap[current!.parentId!];
      level++;
    }
    return level;
  }
}
