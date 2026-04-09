import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/mappers/currency_mapper.dart';
import 'package:qayd/data/models/currency_model.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteCurrencyRepository implements CurrencyRepository {
  SqliteCurrencyRepository(this._db);

  final Database _db;

  @override
  Future<Result<List<CurrencyCode>>> getAll({bool onlyActive = false}) async {
    try {
      final baseRes = await getBaseCurrencyCode();
      final baseCode = baseRes.valueOrNull ?? 'SAR';

      final whereClause = onlyActive ? 'is_active = 1' : null;
      final maps = await _db.query(
        'currencies',
        where: whereClause,
        orderBy: 'is_predefined DESC, code ASC',
      );
      final list = maps
          .map((m) => CurrencyMapper.toEntity(CurrencyModel.fromMap(m)))
          .toList();

      // Sort: base currency first, then active status, then original repository order (predefined first)
      list.sort((a, b) {
        if (a.code == baseCode) return -1;
        if (b.code == baseCode) return 1;

        if (a.isActive != b.isActive) {
          return a.isActive ? -1 : 1;
        }
        return 0; // Maintain relative order from DB
      });

      return Success(list);
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل تحميل العملات: $e'));
    }
  }

  @override
  Future<Result<CurrencyCode?>> getByCode(String code) async {
    try {
      final maps = await _db.query(
        'currencies',
        where: 'code = ?',
        whereArgs: [code],
        limit: 1,
      );
      if (maps.isEmpty) return const Success(null);
      return Success(
          CurrencyMapper.toEntity(CurrencyModel.fromMap(maps.first)));
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل تحميل العملة: $e'));
    }
  }

  @override
  Future<Result<void>> save(CurrencyCode currency,
      {bool isPredefined = false}) async {
    try {
      final model =
          CurrencyMapper.toModel(currency, isPredefined: isPredefined);
      await _db.insert(
        'currencies',
        model.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(DatabaseFailure(messageAr: 'فشل حفظ العملة: $e'));
    }
  }

  @override
  Future<Result<void>> toggleActiveStatus(String code, bool isActive) async {
    try {
      await _db.update(
        'currencies',
        {'is_active': isActive ? 1 : 0},
        where: 'code = ?',
        whereArgs: [code],
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(
          DatabaseFailure(messageAr: 'فشل تغيير حالة العملة: $e'));
    }
  }

  @override
  Future<Result<String>> getBaseCurrencyCode() async {
    try {
      final maps = await _db.query(
        'app_settings',
        where: 'key = ?',
        whereArgs: ['base_currency_code'],
        limit: 1,
      );
      if (maps.isEmpty) return const Success('YER');
      return Success(maps.first['value']! as String);
    } catch (e) {
      return const Success('YER'); // Fallback to YER
    }
  }

  @override
  Future<Result<void>> setBaseCurrencyCode(String code) async {
    try {
      await _db.insert(
        'app_settings',
        {'key': 'base_currency_code', 'value': code},
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (e) {
      return FailureResult(
          DatabaseFailure(messageAr: 'فشل حفظ العملة الأساسية: $e'));
    }
  }
}
