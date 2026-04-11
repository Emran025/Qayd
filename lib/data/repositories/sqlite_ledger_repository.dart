import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/mappers/currency_mapper.dart';
import 'package:qayd/data/mappers/ledger_entry_mapper.dart';
import 'package:qayd/data/models/currency_model.dart';
import 'package:qayd/data/models/ledger_entry_model.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/repositories/ledger_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/transaction_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteLedgerRepository implements LedgerRepository {
  SqliteLedgerRepository(this._db);

  final Database _db;

  static const _table = 'ledger_entries';

  Future<List<LedgerEntry>> _mapEntryRows(
      List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];

    final currencyMaps = await _db.query('currencies');
    final currencyLookup = {
      for (final m in currencyMaps)
        m['code']! as String: CurrencyMapper.toEntity(CurrencyModel.fromMap(m))
    };

    return rows.map((m) {
      final model = LedgerEntryModel.fromMap(m);
      final currency = currencyLookup[model.currencyCode]!;
      return LedgerEntryMapper.toEntity(model, currency);
    }).toList(growable: false);
  }

  @override
  Future<Result<void>> createEntries(List<LedgerEntry> entries) async {
    if (entries.isEmpty) return const Success(null);
    try {
      await _db.transaction((txn) async {
        for (final e in entries) {
          await txn.insert(
            _table,
            LedgerEntryMapper.toModel(e).toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حفظ قيود دفتر الأستاذ.'),
      );
    }
  }

  @override
  Future<Result<List<LedgerEntry>>> getEntriesForAccount(
    AccountId accountId, {
    DateRange? dateRange,
  }) async {
    try {
      final query = StringBuffer('''
        SELECT e.* 
        FROM $_table e
        JOIN vouchers v ON e.voucher_id = v.id
        WHERE e.account_id = ? AND v.state <> 'withdrawn'
      ''');
      final args = <Object>[accountId.value];
      if (dateRange != null) {
        query.write(' AND e.date >= ? AND e.date <= ?');
        args.add(dateRange.start.toIso8601String());
        args.add(dateRange.end.toIso8601String());
      }
      query.write(' ORDER BY e.date ASC, e.created_at ASC');
      
      final rows = await _db.rawQuery(query.toString(), args);
      return Success(await _mapEntryRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة حركات الحساب.'),
      );
    }
  }

  @override
  Future<Result<List<LedgerEntry>>> getEntriesForTransaction(
    TransactionId transactionId,
  ) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'transaction_id = ?',
        whereArgs: [transactionId.value],
        orderBy: 'created_at ASC',
      );
      return Success(await _mapEntryRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة حركة مزدوجة القيد.'),
      );
    }
  }

  @override
  Future<Result<List<LedgerEntry>>> getEntriesForVoucher(
      VoucherId voucherId) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'voucher_id = ?',
        whereArgs: [voucherId.value],
        orderBy: 'created_at ASC',
      );
      return Success(await _mapEntryRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة قيود السند.'),
      );
    }
  }

  @override
  Future<Result<List<LedgerEntry>>> getAllEntries(
      {DateRange? dateRange}) async {
    try {
      final query = StringBuffer('''
        SELECT e.* 
        FROM $_table e
        JOIN vouchers v ON e.voucher_id = v.id
        WHERE v.state <> 'withdrawn'
      ''');
      final args = <Object>[];
      if (dateRange != null) {
        query.write(' AND e.date >= ? AND e.date <= ?');
        args.add(dateRange.start.toIso8601String());
        args.add(dateRange.end.toIso8601String());
      }
      query.write(' ORDER BY e.date ASC, e.created_at ASC');

      final rows = await _db.rawQuery(query.toString(), args);
      return Success(await _mapEntryRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة دفتر الأستاذ.'),
      );
    }
  }
}
