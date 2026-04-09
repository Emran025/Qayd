import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/domain/repositories/accrual_repository.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteAccrualRepository implements AccrualRepository {
  SqliteAccrualRepository(this._db);

  final Database _db;
  static const _table = 'accrual_components';

  @override
  Future<Result<List<AccrualComponent>>> getAll() async {
    try {
      final rows = await _db.query(_table, orderBy: 'next_due_date ASC');
      return Success(rows.map(_fromRow).toList());
    } catch (_) {
      return const FailureResult(
          DatabaseFailure(messageAr: 'تعذر قراءة الاستحقاقات.'));
    }
  }

  @override
  Future<Result<AccrualComponent?>> getById(String id) async {
    try {
      final rows =
          await _db.query(_table, where: 'id = ?', whereArgs: [id], limit: 1);
      if (rows.isEmpty) return const Success(null);
      return Success(_fromRow(rows.first));
    } catch (_) {
      return const FailureResult(
          DatabaseFailure(messageAr: 'تعذر قراءة الاستحقاق.'));
    }
  }

  @override
  Future<Result<List<AccrualComponent>>> getByCostCenter(
      String costCenterId) async {
    try {
      final rows = await _db.query(_table,
          where: 'cost_center_id = ?', whereArgs: [costCenterId]);
      return Success(rows.map(_fromRow).toList());
    } catch (_) {
      return const FailureResult(
          DatabaseFailure(messageAr: 'تعذر قراءة استحقاقات المركز.'));
    }
  }

  @override
  Future<Result<List<AccrualComponent>>> getDueAccruals(DateTime at) async {
    try {
      final dateStr = at.toIso8601String().split('T').first;
      final rows = await _db.query(
        _table,
        where: 'next_due_date <= ? AND is_active = 1',
        whereArgs: [dateStr],
      );
      return Success(rows.map(_fromRow).toList());
    } catch (_) {
      return const FailureResult(
          DatabaseFailure(messageAr: 'تعذر قراءة الاستحقاقات المستحقة.'));
    }
  }

  @override
  Future<Result<void>> save(AccrualComponent component) async {
    try {
      await _db.insert(
        _table,
        _toRow(component),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
          DatabaseFailure(messageAr: 'تعذر حفظ الاستحقاق.'));
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.delete(_table, where: 'id = ?', whereArgs: [id]);
      return const Success(null);
    } catch (_) {
      return const FailureResult(
          DatabaseFailure(messageAr: 'تعذر حذف الاستحقاق.'));
    }
  }

  AccrualComponent _fromRow(Map<String, Object?> r) => AccrualComponent(
        id: r['id'] as String,
        name: r['name'] as String,
        description: r['description'] as String?,
        totalAmountMinor: r['total_amount_minor'] as int,
        currencyCode: r['currency_code'] as String,
        sourceAccountId: r['source_account_id'] as String?,
        destinationAccountId: r['destination_account_id'] as String,
        costCenterId: r['cost_center_id'] as String?,
        categoryId: r['category_id'] as String?,
        frequency: AccrualFrequency.values.byName(r['frequency'] as String),
        startDate: DateTime.parse(r['start_date'] as String),
        nextDueDate: DateTime.parse(r['next_due_date'] as String),
        isActive: (r['is_active'] as int) == 1,
        createdAt: DateTime.parse(r['created_at'] as String),
      );

  Map<String, Object?> _toRow(AccrualComponent c) => {
        'id': c.id,
        'name': c.name,
        'description': c.description,
        'total_amount_minor': c.totalAmountMinor,
        'currency_code': c.currencyCode,
        'source_account_id': c.sourceAccountId,
        'destination_account_id': c.destinationAccountId,
        'cost_center_id': c.costCenterId,
        'category_id': c.categoryId,
        'frequency': c.frequency.name,
        'start_date': c.startDate.toIso8601String(),
        'next_due_date': c.nextDueDate.toIso8601String(),
        'is_active': c.isActive ? 1 : 0,
        'created_at': c.createdAt.toIso8601String(),
      };
}
