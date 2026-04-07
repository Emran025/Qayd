import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/database/transaction_runner.dart';
import 'package:qayd/data/mappers/currency_mapper.dart';
import 'package:qayd/data/mappers/ledger_entry_mapper.dart';
import 'package:qayd/data/mappers/voucher_mapper.dart';
import 'package:qayd/data/models/currency_model.dart';
import 'package:qayd/data/models/voucher_model.dart';
import 'package:qayd/data/search/fts_voucher_query_builder.dart';
import 'package:qayd/domain/entities/ledger_entry.dart';
import 'package:qayd/domain/entities/voucher.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/date_range.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';
import 'package:qayd/domain/value_objects/voucher_query_filter.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteVoucherRepository implements VoucherRepository {
  SqliteVoucherRepository(this._db, this._transactionRunner);

  final Database _db;
  final DatabaseTransactionRunner _transactionRunner;

  static const _vouchers = 'vouchers';
  static const _ledger = 'ledger_entries';
  static const _fts = 'vouchers_fts';

  static void _appendFilterClauses(
    VoucherQueryFilter? filter,
    String tablePrefix,
    List<String> whereParts,
    List<Object> args,
  ) {
    if (filter == null) {
      return;
    }
    final p = tablePrefix;
    if (filter.state != null) {
      whereParts.add('${p}state = ?');
      args.add(filter.state!.name);
    }
    if (filter.type != null) {
      whereParts.add('${p}type = ?');
      args.add(filter.type!.name);
    }
    if (filter.counterpartyId != null) {
      whereParts.add('${p}counterparty_id = ?');
      args.add(filter.counterpartyId!.value);
    }
    if (filter.affectedAccountId != null) {
      whereParts.add('${p}affected_account_id = ?');
      args.add(filter.affectedAccountId!.value);
    }
    if (filter.involvedAccountId != null) {
      whereParts.add('(${p}affected_account_id = ? OR ${p}counterparty_id = ? OR ${p}linked_party_id = ?)');
      args.add(filter.involvedAccountId!.value);
      args.add(filter.involvedAccountId!.value);
      args.add(filter.involvedAccountId!.value);
    }
    if (filter.dateRange != null) {
      whereParts.add('${p}date >= ? AND ${p}date <= ?');
      args.add(filter.dateRange!.start.toIso8601String());
      args.add(filter.dateRange!.end.toIso8601String());
    }
    if (filter.excludeTripartite == true) {
      whereParts.add('${p}transfer_group_id IS NULL');
    }
    if (filter.onlyTripartite == true) {
      whereParts.add('${p}transfer_group_id IS NOT NULL');
    }
    if (filter.costCenterId != null) {
      whereParts.add('${p}id IN (SELECT voucher_id FROM voucher_cost_centers WHERE cost_center_id = ?)');
      args.add(filter.costCenterId!);
    }
  }

  Future<List<Voucher>> _mapVoucherRows(List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];
    
    // Pre-fetch all currencies for lookup
    final currencyMaps = await _db.query('currencies');
    final currencyLookup = {
      for (final m in currencyMaps)
        m['code']! as String: CurrencyMapper.toEntity(CurrencyModel.fromMap(m))
    };

    return rows.map((m) {
      final model = VoucherModel.fromMap(m);
      final currency = currencyLookup[model.currencyCode]!;
      return VoucherMapper.toEntity(model, currency);
    }).toList(growable: false);
  }

  @override
  Future<Result<Voucher>> getById(VoucherId id) async {
    try {
      final rows = await _db.query(
        _vouchers,
        where: 'id = ?',
        whereArgs: [id.value],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'السند غير موجود.',
            code: 'voucher_not_found',
          ),
        );
      }
      final model = VoucherModel.fromMap(rows.first);
      final currencyMaps = await _db.query(
        'currencies',
        where: 'code = ?',
        whereArgs: [model.currencyCode],
        limit: 1,
      );
      final currency = CurrencyMapper.toEntity(CurrencyModel.fromMap(currencyMaps.first));
      return Success(VoucherMapper.toEntity(model, currency));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة السند.'),
      );
    }
  }

  @override
  Future<Result<List<Voucher>>> getAll({
    VoucherQueryFilter? filter,
    int? limit,
    int? offset,
  }) async {
    try {
      final whereParts = <String>[];
      final args = <Object>[];
      _appendFilterClauses(filter, '', whereParts, args);
      final where =
          whereParts.isEmpty ? null : whereParts.join(' AND ');
      var sql =
          'SELECT *, ' 
          '(SELECT COUNT(*) FROM $_vouchers c WHERE c.origin_voucher_id = $_vouchers.id) as reversal_count, '
          '(SELECT id FROM $_vouchers c WHERE c.origin_voucher_id = $_vouchers.id ORDER BY created_at ASC LIMIT 1) as first_child_id '
          'FROM $_vouchers${where != null ? ' WHERE $where' : ''} ORDER BY date DESC, created_at DESC';
      if (limit != null) {
        sql += ' LIMIT ?';
        args.add(limit);
        if (offset != null) {
          sql += ' OFFSET ?';
          args.add(offset);
        }
      }
      final rows = await _db.rawQuery(sql, args);
      return Success(await _mapVoucherRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة السندات.'),
      );
    }
  }

  @override
  Future<Result<List<Voucher>>> getByCounterparty(
    AccountId counterpartyId, {
    DateRange? dateRange,
  }) async {
    try {
      final whereParts = <String>['counterparty_id = ?'];
      final args = <Object>[counterpartyId.value];
      if (dateRange != null) {
        whereParts.add('date >= ? AND date <= ?');
        args.add(dateRange.start.toIso8601String());
        args.add(dateRange.end.toIso8601String());
      }
      final where = whereParts.join(' AND ');
      final rows = await _db.query(
        _vouchers,
        where: where,
        whereArgs: args,
        orderBy: 'date DESC, created_at DESC',
      );
      return Success(await _mapVoucherRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة سندات الطرف.'),
      );
    }
  }

  @override
  Future<Result<void>> save(Voucher voucher) async {
    try {
      final map = VoucherMapper.toModel(voucher).toMap();
      await _db.insert(
        _vouchers,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حفظ السند.'),
      );
    }
  }

  @override
  Future<Result<void>> deleteDraft(VoucherId id) async {
    try {
      final n = await _db.delete(
        _vouchers,
        where: 'id = ? AND state = ?',
        whereArgs: [id.value, 'draft'],
      );
      if (n == 0) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'لا يمكن حذف السند أو ليس مسودة.',
            code: 'voucher_delete_invalid',
          ),
        );
      }
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حذف السند.'),
      );
    }
  }

  @override
  Future<Result<List<Voucher>>> search({
    required String queryText,
    VoucherQueryFilter? filter,
  }) async {
    final trimmed = queryText.trim();
    if (trimmed.isEmpty) {
      return getAll(filter: filter);
    }
    final match = FtsVoucherQueryBuilder.matchExpression(trimmed);
    if (match != null) {
      try {
        final whereParts = <String>[
          'v.rowid IN (SELECT rowid FROM $_fts WHERE $_fts MATCH ?)',
        ];
        final args = <Object>[match];
        _appendFilterClauses(filter, 'v.', whereParts, args);
        final where = whereParts.join(' AND ');
        final sql =
            'SELECT v.* FROM $_vouchers v WHERE $where ORDER BY v.date DESC, v.created_at DESC';
        final rows = await _db.rawQuery(sql, args);
        return Success(await _mapVoucherRows(rows));
      } catch (_) {
        // FTS unavailable or malformed query — fall through to LIKE.
      }
    }
    return _searchLike(trimmed, filter);
  }

  Future<Result<List<Voucher>>> _searchLike(
    String trimmed,
    VoucherQueryFilter? filter,
  ) async {
    try {
      final q = '%$trimmed%';
      final whereParts = <String>[
        '(description LIKE ? OR notes LIKE ? OR reference_number LIKE ? OR id LIKE ?)',
      ];
      final args = <Object>[q, q, q, q];
      _appendFilterClauses(filter, '', whereParts, args);
      final where = whereParts.join(' AND ');
      final rows = await _db.query(
        _vouchers,
        where: where,
        whereArgs: args,
        orderBy: 'date DESC, created_at DESC',
      );
      return Success(await _mapVoucherRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر البحث في السندات.'),
      );
    }
  }

  @override
  Future<Result<int>> count({VoucherQueryFilter? filter}) async {
    try {
      final whereParts = <String>[];
      final args = <Object>[];
      _appendFilterClauses(filter, '', whereParts, args);
      final where =
          whereParts.isEmpty ? null : whereParts.join(' AND ');
      final rows = await _db.rawQuery(
        'SELECT COUNT(*) AS c FROM $_vouchers${where != null ? ' WHERE $where' : ''}',
        args,
      );
      final raw = rows.first['c'];
      final c = raw is int ? raw : (raw as num).toInt();
      return Success(c);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر عد السندات.'),
      );
    }
  }

  @override
  Future<Result<void>> saveWithLedgerEntries({
    required Voucher voucher,
    required List<LedgerEntry> ledgerEntries,
  }) async {
    if (ledgerEntries.isEmpty) {
      return save(voucher);
    }
    for (final e in ledgerEntries) {
      if (e.voucherId.value != voucher.id.value) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'قيود السند لا تطابق معرّف السند.',
            code: 'ledger_voucher_mismatch',
          ),
        );
      }
    }
    try {
      await _transactionRunner.run((txn) async {
        await txn.insert(
          _vouchers,
          VoucherMapper.toModel(voucher).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        for (final e in ledgerEntries) {
          await txn.insert(
            _ledger,
            LedgerEntryMapper.toModel(e).toMap(),
            conflictAlgorithm: ConflictAlgorithm.abort,
          );
        }
      });
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(
          messageAr: 'تعذر تأكيد السند وحفظ القيود. تم التراجع عن العملية.',
        ),
      );
    }
  }

  @override
  Future<Result<void>> saveTripartitePair({
    required Voucher receiptVoucher,
    required Voucher paymentVoucher,
  }) async {
    try {
      await _transactionRunner.run((txn) async {
        await txn.insert(
          _vouchers,
          VoucherMapper.toModel(receiptVoucher).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        await txn.insert(
          _vouchers,
          VoucherMapper.toModel(paymentVoucher).toMap(),
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
      });
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(
          messageAr: 'تعذر حفظ سندات التحويل الثلاثي. تم التراجع عن العملية.',
        ),
      );
    }
  }

  @override
  Future<Result<List<Voucher>>> getByTransferGroupId(
    String transferGroupId,
  ) async {
    try {
      final rows = await _db.query(
        _vouchers,
        where: 'transfer_group_id = ?',
        whereArgs: [transferGroupId],
        orderBy: 'created_at ASC',
      );
      return Success(await _mapVoucherRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(
          messageAr: 'تعذر قراءة سندات مجموعة التحويل.',
        ),
      );
    }
  }

  // ── Threaded Financial Interactions ──────────────────────────────────────

  @override
  Future<Result<List<Voucher>>> getByOriginVoucherId(VoucherId originId) async {
    try {
      final rows = await _db.query(
        _vouchers,
        where: 'origin_voucher_id = ?',
        whereArgs: [originId.value],
        orderBy: 'created_at ASC',
      );
      return Success(await _mapVoucherRows(rows));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(
          messageAr: 'تعذر قراءة سندات المرتجعات والتسويات.',
        ),
      );
    }
  }

  @override
  Future<Result<Voucher?>> findReciprocalMatch({
    required int amountMinor,
    required String currencyCode,
    required String counterpartyAccountId,
    required String type,
    required DateTime referenceDate,
  }) async {
    try {
      // Determine the inverse type to match against
      final inverseType = type == 'receipt' ? 'payment' : 'receipt';

      // Calculate ±24-hour window
      final windowStart = referenceDate.subtract(const Duration(hours: 24));
      final windowEnd = referenceDate.add(const Duration(hours: 24));

      final rows = await _db.query(
        _vouchers,
        where:
            'amount_minor = ? AND currency_code = ? AND counterparty_id = ? '
            'AND type = ? AND state = ? AND date >= ? AND date <= ?',
        whereArgs: [
          amountMinor,
          currencyCode,
          counterpartyAccountId,
          inverseType,
          'draft',
          windowStart.toIso8601String(),
          windowEnd.toIso8601String(),
        ],
        limit: 1,
        orderBy: 'created_at DESC',
      );

      if (rows.isEmpty) {
        return const Success(null);
      }

      final vouchers = await _mapVoucherRows(rows);
      return Success(vouchers.first);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(
          messageAr: 'تعذر البحث عن السند المقابل.',
        ),
      );
    }
  }
}
