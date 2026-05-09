import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/fiscal_period.dart';
import 'package:qayd/domain/entities/ledger_account_snapshot.dart';
import 'package:qayd/domain/repositories/fiscal_period_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteFiscalPeriodRepository implements FiscalPeriodRepository {
  SqliteFiscalPeriodRepository(this._db);

  final Database _db;

  static const _periods = 'fiscal_periods';
  static const _snapshots = 'account_snapshots';

  FiscalPeriod _periodFromRow(Map<String, Object?> m) {
    return FiscalPeriod(
      id: m['id']! as String,
      name: m['name']! as String,
      startDate: DateTime.parse(m['start_date']! as String),
      endDate: DateTime.parse(m['end_date']! as String),
      status: _parseStatus(m['status']! as String),
      closedAt: m['closed_at'] != null
          ? DateTime.parse(m['closed_at']! as String)
          : null,
      closingVoucherId: m['closing_voucher_id'] != null
          ? VoucherId(m['closing_voucher_id']! as String)
          : null,
      aggregateSnapshotHash: m['aggregate_snapshot_hash'] as String?,
      aggregateSignatureHex: m['aggregate_signature_hex'] as String?,
      signerPublicKeyHex: m['signer_public_key_hex'] as String?,
    );
  }

  FiscalPeriodStatus _parseStatus(String raw) {
    return switch (raw) {
      'open' => FiscalPeriodStatus.open,
      'closing' => FiscalPeriodStatus.closing,
      'closed' => FiscalPeriodStatus.closed,
      _ => FiscalPeriodStatus.open,
    };
  }

  String _statusString(FiscalPeriodStatus s) => switch (s) {
        FiscalPeriodStatus.open => 'open',
        FiscalPeriodStatus.closing => 'closing',
        FiscalPeriodStatus.closed => 'closed',
      };

  LedgerAccountSnapshot _snapshotFromRow(Map<String, Object?> m) {
    return LedgerAccountSnapshot(
      id: m['id']! as String,
      periodId: m['period_id']! as String,
      accountId: AccountId(m['account_id']! as String),
      balanceMinorUnits: m['balance_minor_units']! as int,
      currencyCode: m['currency_code']! as String,
      rowHash: m['row_hash']! as String,
    );
  }

  @override
  Future<Result<List<FiscalPeriod>>> listAllOrdered() async {
    try {
      final rows = await _db.query(
        _periods,
        orderBy: 'start_date ASC',
      );
      return Success(rows.map(_periodFromRow).toList(growable: false));
    } catch (_) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.accountsCouldNotBe),
      );
    }
  }

  @override
  Future<Result<FiscalPeriod?>> findLatestClosed() async {
    try {
      final rows = await _db.query(
        _periods,
        where: "status = 'closed'",
        orderBy: 'end_date DESC',
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      return Success(_periodFromRow(rows.first));
    } catch (_) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.accountsCouldNotBe),
      );
    }
  }

  @override
  Future<Result<FiscalPeriod?>> findOpenPeriod() async {
    try {
      final rows = await _db.query(
        _periods,
        where: "status = 'open'",
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      return Success(_periodFromRow(rows.first));
    } catch (_) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.accountsCouldNotBe),
      );
    }
  }

  @override
  Future<Result<void>> insert(FiscalPeriod period) async {
    try {
      await _db.insert(_periods, {
        'id': period.id,
        'name': period.name,
        'start_date': period.startDate.toIso8601String(),
        'end_date': period.endDate.toIso8601String(),
        'status': _statusString(period.status),
        'closed_at': period.closedAt?.toIso8601String(),
        'closing_voucher_id': period.closingVoucherId?.value,
        'aggregate_snapshot_hash': period.aggregateSnapshotHash,
        'aggregate_signature_hex': period.aggregateSignatureHex,
        'signer_public_key_hex': period.signerPublicKeyHex,
      });
      return const Success(null);
    } catch (_) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.accountsCouldNotBe),
      );
    }
  }

  @override
  Future<Result<List<LedgerAccountSnapshot>>> snapshotsForPeriod(
    String periodId,
  ) async {
    try {
      final rows = await _db.query(
        _snapshots,
        where: 'period_id = ?',
        whereArgs: [periodId],
      );
      return Success(rows.map(_snapshotFromRow).toList(growable: false));
    } catch (_) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.accountsCouldNotBe),
      );
    }
  }

  @override
  Future<Result<void>> closePeriodWithSnapshots({
    required FiscalPeriod closed,
    required List<LedgerAccountSnapshot> snapshots,
  }) async {
    try {
      await _db.transaction((txn) async {
        await txn.update(
          _periods,
          {
            'status': _statusString(closed.status),
            'closed_at': closed.closedAt?.toIso8601String(),
            'closing_voucher_id': closed.closingVoucherId?.value,
            'aggregate_snapshot_hash': closed.aggregateSnapshotHash,
            'aggregate_signature_hex': closed.aggregateSignatureHex,
            'signer_public_key_hex': closed.signerPublicKeyHex,
          },
          where: 'id = ?',
          whereArgs: [closed.id],
        );
        for (final s in snapshots) {
          await txn.insert(_snapshots, {
            'id': s.id,
            'period_id': s.periodId,
            'account_id': s.accountId.value,
            'balance_minor_units': s.balanceMinorUnits,
            'currency_code': s.currencyCode,
            'row_hash': s.rowHash,
          });
        }
      });
      return const Success(null);
    } catch (_) {
      return FailureResult(
        DatabaseFailure(messageAr: AppStrings.accountsCouldNotBe),
      );
    }
  }
}
