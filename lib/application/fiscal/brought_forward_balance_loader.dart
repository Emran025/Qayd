import 'package:qayd/application/fiscal/fiscal_period_policy.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/repositories/fiscal_period_repository.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/value_objects/date_range.dart';

/// Snapshot base + ledger lines after the latest closed period (delta).
typedef BroughtForwardBundle = ({
  Map<String, Map<String, int>> snapshotMinorByAccountAndCurrency,
  List<LedgerEntry> deltaEntries,
});

abstract final class BroughtForwardBalanceLoader {
  static Future<Result<BroughtForwardBundle>> load({
    required FiscalPeriodRepository fiscal,
    required LedgerRepository ledger,
    DateTime? settlementAnchorDate,
  }) async {
    final closedR = await fiscal.findLatestClosed();
    if (closedR.isFailure) {
      return FailureResult(closedR.failureOrNull!);
    }
    final latestClosed = closedR.valueOrNull;
    if (latestClosed == null) {
      final allR = settlementAnchorDate == null
          ? await ledger.getAllEntries()
          : await ledger.getAllEntries(
              dateRange: DateRange(
                start: settlementAnchorDate,
                end: DateTime(2100, 12, 31, 23, 59, 59),
              ),
            );
      if (allR.isFailure) {
        return FailureResult(allR.failureOrNull!);
      }
      return Success((
        snapshotMinorByAccountAndCurrency: <String, Map<String, int>>{},
        deltaEntries: allR.valueOrNull!,
      ));
    }
    final snapR = await fiscal.snapshotsForPeriod(latestClosed.id);
    if (snapR.isFailure) {
      return FailureResult(snapR.failureOrNull!);
    }
    final base = <String, Map<String, int>>{};
    for (final s in snapR.valueOrNull!) {
      final acc = s.accountId.value;
      base.putIfAbsent(acc, () => <String, int>{});
      base[acc]![s.currencyCode] =
          (base[acc]![s.currencyCode] ?? 0) + s.balanceMinorUnits;
    }
    final fiscalOpenStart =
        FiscalPeriodPolicy.firstMomentAfterClosedEnd(latestClosed.endDate);
    var openStart = fiscalOpenStart;
    if (settlementAnchorDate != null && settlementAnchorDate.isAfter(openStart)) {
      openStart = settlementAnchorDate;
    }
    final deltaR = await ledger.getAllEntries(
      dateRange: DateRange(
        start: openStart,
        end: DateTime(2100, 12, 31, 23, 59, 59),
      ),
    );
    if (deltaR.isFailure) {
      return FailureResult(deltaR.failureOrNull!);
    }
    return Success((
      snapshotMinorByAccountAndCurrency: base,
      deltaEntries: deltaR.valueOrNull!,
    ));
  }
}
