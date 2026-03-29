import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/mappers/account_mapper.dart';
import 'package:qayd/data/models/account_model.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteAccountRepository implements AccountRepository {
  SqliteAccountRepository(this._db);

  final Database _db;

  static const _table = 'accounts';

  @override
  Future<Result<Account>> getById(AccountId id) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'id = ?',
        whereArgs: [id.value],
        limit: 1,
      );
      if (rows.isEmpty) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'الحساب غير موجود.',
            code: 'account_not_found',
          ),
        );
      }
      return Success(AccountMapper.toEntity(AccountModel.fromMap(rows.first)));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة الحساب من قاعدة البيانات.'),
      );
    }
  }

  @override
  Future<Result<List<Account>>> getAll({bool activeOnly = false}) async {
    try {
      final rows = await _db.query(
        _table,
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'name COLLATE NOCASE',
      );
      return Success(
        rows
            .map((m) => AccountMapper.toEntity(AccountModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة قائمة الحسابات.'),
      );
    }
  }

  @override
  Future<Result<List<Account>>> getChildrenOf(AccountId parentId) async {
    try {
      final rows = await _db.query(
        _table,
        where: 'parent_id = ?',
        whereArgs: [parentId.value],
        orderBy: 'name COLLATE NOCASE',
      );
      return Success(
        rows
            .map((m) => AccountMapper.toEntity(AccountModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة الحسابات الفرعية.'),
      );
    }
  }

  @override
  Future<Result<List<Account>>> getDescendantsOf(AccountId parentId) async {
    try {
      final rows = await _db.rawQuery(
        '''
WITH RECURSIVE descendants AS (
  SELECT id FROM $_table WHERE parent_id = ?
  UNION ALL
  SELECT a.id FROM $_table a
  INNER JOIN descendants d ON a.parent_id = d.id
)
SELECT a.* FROM $_table a
WHERE a.id IN (SELECT id FROM descendants)
ORDER BY a.name COLLATE NOCASE
''',
        [parentId.value],
      );
      return Success(
        rows
            .map((m) => AccountMapper.toEntity(AccountModel.fromMap(m)))
            .toList(growable: false),
      );
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة الحسابات التابعة.'),
      );
    }
  }

  @override
  Future<Result<void>> save(Account account) async {
    try {
      final map = AccountMapper.toModel(account).toMap();
      await _db.insert(
        _table,
        map,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حفظ الحساب.'),
      );
    }
  }

  @override
  Future<Result<void>> createBatch(List<Account> accounts) async {
    try {
      await _db.transaction((txn) async {
        for (final a in accounts) {
          final map = AccountMapper.toModel(a).toMap();
          await txn.insert(
            _table,
            map,
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
      });
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر إنشاء الحسابات دفعة واحدة.'),
      );
    }
  }

  @override
  Future<Result<void>> delete(AccountId id) async {
    try {
      final n = await _db.delete(
        _table,
        where: 'id = ?',
        whereArgs: [id.value],
      );
      if (n == 0) {
        return const FailureResult(
          ValidationFailure(
            messageAr: 'الحساب غير موجود.',
            code: 'account_not_found',
          ),
        );
      }
      return const Success(null);
    } on DatabaseException {
      return const FailureResult(
        DatabaseFailure(
          messageAr:
              'تعذر حذف الحساب. قد يوجد حسابات فرعية أو حركات مرتبطة.',
        ),
      );
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حذف الحساب.'),
      );
    }
  }

  @override
  Future<Result<bool>> exists(AccountId id) async {
    try {
      final rows = await _db.rawQuery(
        'SELECT 1 FROM $_table WHERE id = ? LIMIT 1',
        [id.value],
      );
      return Success(rows.isNotEmpty);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر التحقق من وجود الحساب.'),
      );
    }
  }
}
