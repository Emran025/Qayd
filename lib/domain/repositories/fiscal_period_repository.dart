import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/fiscal_period.dart';
import 'package:qayd/domain/entities/ledger_account_snapshot.dart';

abstract interface class FiscalPeriodRepository {
  Future<Result<List<FiscalPeriod>>> listAllOrdered();

  Future<Result<FiscalPeriod?>> findLatestClosed();

  Future<Result<FiscalPeriod?>> findOpenPeriod();

  Future<Result<void>> insert(FiscalPeriod period);

  Future<Result<List<LedgerAccountSnapshot>>> snapshotsForPeriod(String periodId);

  Future<Result<void>> closePeriodWithSnapshots({
    required FiscalPeriod closed,
    required List<LedgerAccountSnapshot> snapshots,
  });
}
