import 'dart:math';

import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

final class SqliteCostCenterRepository implements CostCenterRepository {
  SqliteCostCenterRepository(this._db);

  final Database _db;

  static const _centers = 'cost_centers';
  static const _dims = 'cost_center_dimensions';
  static const _cats = 'cost_center_dimension_categories';
  static const _vcc = 'voucher_cost_centers';
  static const _vdt = 'voucher_dimension_tags';

  // ── Cost Centers ──────────────────────────────────────────────────────────

  @override
  Future<Result<List<CostCenter>>> getAll({bool activeOnly = false}) async {
    try {
      final rows = await _db.query(
        _centers,
        where: activeOnly ? 'is_active = 1' : null,
        orderBy: 'name COLLATE NOCASE',
      );
      return Success(rows.map(_centerFromRow).toList(growable: false));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة مراكز التكلفة.'),
      );
    }
  }

  @override
  Future<Result<CostCenter?>> getById(String id) async {
    try {
      final rows = await _db.query(
        _centers,
        where: 'id = ?',
        whereArgs: [id],
        limit: 1,
      );
      if (rows.isEmpty) return const Success(null);
      return Success(_centerFromRow(rows.first));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة مركز التكلفة.'),
      );
    }
  }

  @override
  Future<Result<void>> save(CostCenter center) async {
    try {
      await _db.insert(
        _centers,
        _centerToRow(center),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حفظ مركز التكلفة.'),
      );
    }
  }

  @override
  Future<Result<void>> delete(String id) async {
    try {
      await _db.delete(_centers, where: 'id = ?', whereArgs: [id]);
      return const Success(null);
    } on DatabaseException {
      return const FailureResult(
        DatabaseFailure(
          messageAr: 'تعذر حذف مركز التكلفة — قد تكون هناك سندات مرتبطة.',
        ),
      );
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حذف مركز التكلفة.'),
      );
    }
  }

  // ── Dimensions ────────────────────────────────────────────────────────────

  @override
  Future<Result<List<CostCenterDimension>>> getAllDimensions({
    String? costCenterId,
    bool activeOnly = false,
  }) async {
    try {
      final whereParts = <String>[];
      final whereArgs = <Object?>[];

      if (activeOnly) {
        whereParts.add('is_active = 1');
      }
      if (costCenterId != null) {
        // Include global (null) dims and dims specific to this center
        whereParts.add('(cost_center_id IS NULL OR cost_center_id = ?)');
        whereArgs.add(costCenterId);
      }


      final rows = await _db.rawQuery(
        '''
SELECT d.*, c.name AS cat_name, c.icon_name AS cat_icon, c.is_default AS cat_is_default
FROM $_dims d
LEFT JOIN $_cats c ON d.category = c.id
${whereParts.isEmpty ? '' : 'WHERE ${whereParts.join(' AND ')}'}
ORDER BY d.category, d.name COLLATE NOCASE
''',
        whereArgs,
      );
      return Success(rows.map(_dimFromRow).toList(growable: false));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة الأبعاد.'),
      );
    }
  }

  @override
  Future<Result<void>> saveDimension(CostCenterDimension dimension) async {
    try {
      await _db.insert(
        _dims,
        _dimToRow(dimension),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حفظ البُعد.'),
      );
    }
  }

  @override
  Future<Result<void>> deleteDimension(String id) async {
    try {
      await _db.delete(_dims, where: 'id = ?', whereArgs: [id]);
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حذف البُعد.'),
      );
    }
  }

  // ── Categories (Classifications) ──────────────────────────────────────────

  @override
  Future<Result<List<CostCenterDimensionCategory>>> getAllCategories() async {
    try {
      final rows = await _db.query(_cats, orderBy: 'is_default DESC, name');
      return Success(rows.map(_catFromRow).toList(growable: false));
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة التصنيفات.'),
      );
    }
  }

  @override
  Future<Result<void>> saveCategory(CostCenterDimensionCategory category) async {
    try {
      await _db.insert(
        _cats,
        _catToRow(category),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حفظ التصنيف.'),
      );
    }
  }

  // ── Voucher Associations ──────────────────────────────────────────────────

  @override
  Future<Result<void>> attachVoucher({
    required String voucherId,
    required String costCenterId,
    List<String> dimensionIds = const [],
  }) async {
    try {
      await _db.transaction((txn) async {
        final now = DateTime.now().toIso8601String();
        final junctionId = _uuid();

        await txn.insert(
          _vcc,
          {
            'id': junctionId,
            'voucher_id': voucherId,
            'cost_center_id': costCenterId,
            'created_at': now,
          },
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );

        for (final dimId in dimensionIds) {
          await txn.insert(
            _vdt,
            {
              'id': _uuid(),
              'voucher_id': voucherId,
              'cost_center_id': costCenterId,
              'dimension_id': dimId,
              'created_at': now,
            },
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
        }
      });
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر ربط السند بمركز التكلفة.'),
      );
    }
  }

  @override
  Future<Result<void>> detachVoucher({
    required String voucherId,
    required String costCenterId,
  }) async {
    try {
      await _db.transaction((txn) async {
        await txn.delete(
          _vdt,
          where: 'voucher_id = ? AND cost_center_id = ?',
          whereArgs: [voucherId, costCenterId],
        );
        await txn.delete(
          _vcc,
          where: 'voucher_id = ? AND cost_center_id = ?',
          whereArgs: [voucherId, costCenterId],
        );
      });
      return const Success(null);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر فك ارتباط السند بمركز التكلفة.'),
      );
    }
  }

  @override
  Future<Result<List<String>>> getCostCenterIdsForVoucher(
    String voucherId,
  ) async {
    try {
      final rows = await _db.query(
        _vcc,
        columns: ['cost_center_id'],
        where: 'voucher_id = ?',
        whereArgs: [voucherId],
      );
      return Success(rows.map((r) => r['cost_center_id'] as String).toList());
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(
          messageAr: 'تعذر قراءة مراكز التكلفة المرتبطة بالسند.',
        ),
      );
    }
  }

  @override
  Future<Result<List<String>>> getVoucherIdsForCostCenter(
    String costCenterId, {
    String? dimensionId,
    DateTime? fromDate,
    DateTime? toDate,
  }) async {
    try {
      if (dimensionId != null) {
        // Filter through dimension tags
        final rows = await _db.query(
          _vdt,
          columns: ['voucher_id'],
          where: 'cost_center_id = ? AND dimension_id = ?',
          whereArgs: [costCenterId, dimensionId],
        );
        return Success(rows.map((r) => r['voucher_id'] as String).toList());
      }

      final rows = await _db.query(
        _vcc,
        columns: ['voucher_id'],
        where: 'cost_center_id = ?',
        whereArgs: [costCenterId],
      );
      return Success(rows.map((r) => r['voucher_id'] as String).toList());
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة السندات لمركز التكلفة.'),
      );
    }
  }

  // ── KPIs ──────────────────────────────────────────────────────────────────

  @override
  Future<Result<Map<String, int>>> getTotalsByCenter(
    String costCenterId,
  ) async {
    try {
      final rows = await _db.rawQuery(
        '''
SELECT v.currency_code, SUM(v.amount_minor) AS total
FROM vouchers v
INNER JOIN voucher_cost_centers vcc ON vcc.voucher_id = v.id
WHERE vcc.cost_center_id = ?
  AND v.state = 'confirmed'
GROUP BY v.currency_code
''',
        [costCenterId],
      );
      final map = <String, int>{};
      for (final r in rows) {
        map[r['currency_code'] as String] = (r['total'] as num).toInt();
      }
      return Success(map);
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر حساب مؤشرات مركز التكلفة.'),
      );
    }
  }

  // ── Analytics ─────────────────────────────────────────────────────────────

  @override
  Future<Result<List<Map<String, dynamic>>>> getMonthlyTrendForCenter(
    String costCenterId, {
    int months = 6,
  }) async {
    try {
      final now = DateTime.now();
      final from = DateTime(now.year, now.month - (months - 1), 1);
      final fromStr = '${from.year}-${from.month.toString().padLeft(2, '0')}-01';
      final rows = await _db.rawQuery(
        '''
SELECT strftime('%Y-%m', v.date) AS month_key,
       SUM(v.amount_minor) AS total_minor
FROM vouchers v
INNER JOIN voucher_cost_centers vcc ON vcc.voucher_id = v.id
WHERE vcc.cost_center_id = ?
  AND v.state = 'confirmed'
  AND v.date >= ?
GROUP BY month_key
ORDER BY month_key ASC
''',
        [costCenterId, fromStr],
      );
      return Success(rows.map((r) => Map<String, dynamic>.from(r)).toList());
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة البيانات الشهرية.'),
      );
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getRecentVouchersForCenter(
    String costCenterId, {
    int limit = 10,
  }) async {
    try {
      final rows = await _db.rawQuery(
        '''
SELECT v.id, v.type, v.amount_minor, v.currency_code,
       v.description, v.date, a.name AS counterparty_name
FROM vouchers v
INNER JOIN voucher_cost_centers vcc ON vcc.voucher_id = v.id
LEFT JOIN accounts a ON a.id = v.counterparty_id
WHERE vcc.cost_center_id = ?
ORDER BY v.date DESC, v.created_at DESC
LIMIT ?
''',
        [costCenterId, limit],
      );

      if (rows.isEmpty) return const Success([]);

      // Fetch dimension tags for these vouchers in a single query
      final placeholders = rows.map((_) => '?').join(', ');
      final voucherIds = rows.map((r) => r['id'] as String).toList();
      final tagRows = await _db.rawQuery(
        '''
SELECT voucher_id, dimension_id
FROM voucher_dimension_tags
WHERE cost_center_id = ? AND voucher_id IN ($placeholders)
''',
        [costCenterId, ...voucherIds],
      );

      // Build voucherId → List<dimensionId> map
      final tagMap = <String, List<String>>{};
      for (final tag in tagRows) {
        final vid = tag['voucher_id'] as String;
        final did = tag['dimension_id'] as String;
        tagMap.putIfAbsent(vid, () => []).add(did);
      }

      return Success(rows.map((r) {
        final id = r['id'] as String;
        return <String, dynamic>{
          ...Map<String, dynamic>.from(r),
          'dimension_ids': tagMap[id] ?? <String>[],
        };
      }).toList());
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة السندات الأخيرة.'),
      );
    }
  }

  @override
  Future<Result<List<Map<String, dynamic>>>> getDimensionBreakdown(
    String costCenterId,
  ) async {
    try {
      final rows = await _db.rawQuery(
        '''
SELECT d.id AS dimension_id,
       d.name AS dimension_name,
       d.category AS category_id,
       COUNT(DISTINCT vdt.voucher_id) AS voucher_count
FROM cost_center_dimensions d
INNER JOIN voucher_dimension_tags vdt ON vdt.dimension_id = d.id
WHERE vdt.cost_center_id = ?
GROUP BY d.id
ORDER BY voucher_count DESC
LIMIT 8
''',
        [costCenterId],
      );
      return Success(rows.map((r) => Map<String, dynamic>.from(r)).toList());
    } catch (_) {
      return const FailureResult(
        DatabaseFailure(messageAr: 'تعذر قراءة توزيع الأبعاد.'),
      );
    }
  }

  // ── Mappers ───────────────────────────────────────────────────────────────

  static CostCenter _centerFromRow(Map<String, Object?> r) {
    return CostCenter.restore(
      id: r['id'] as String,
      name: r['name'] as String,
      type: CostCenterType.values.byName(r['type'] as String),
      description: r['description'] as String?,
      budgetMinorUnits: (r['budget_minor_units'] as int?) ?? 0,
      currencyCode: r['currency_code'] as String,
      isActive: (r['is_active'] as int) == 1,
      isDefault: (r['is_default'] as int) == 1,
      createdAt: DateTime.parse(r['created_at'] as String),
      suspendedAt: r['suspended_at'] != null
          ? DateTime.parse(r['suspended_at'] as String)
          : null,
    );
  }

  static Map<String, Object?> _centerToRow(CostCenter c) => {
        'id': c.id,
        'name': c.name,
        'type': c.type.name,
        'description': c.description,
        'budget_minor_units': c.budgetMinorUnits,
        'currency_code': c.currencyCode,
        'is_active': c.isActive ? 1 : 0,
        'is_default': c.isDefault ? 1 : 0,
        'created_at': c.createdAt.toIso8601String(),
        'suspended_at': c.suspendedAt?.toIso8601String(),
      };

  static CostCenterDimension _dimFromRow(Map<String, Object?> r) {
    return CostCenterDimension(
      id: r['id'] as String,
      name: r['name'] as String,
      category: CostCenterDimensionCategory(
        id: r['category'] as String,
        name: (r['cat_name'] as String?) ?? (r['category'] as String),
        iconName: r['cat_icon'] as String?,
        isDefault: ((r['cat_is_default'] as int?) ?? 0) == 1,
      ),
      costCenterId: r['cost_center_id'] as String?,
      isDefault: (r['is_default'] as int) == 1,
      isActive: (r['is_active'] as int) == 1,
      createdAt: DateTime.parse(r['created_at'] as String),
    );
  }

  static Map<String, Object?> _dimToRow(CostCenterDimension d) => {
        'id': d.id,
        'name': d.name,
        'category': d.category.id,
        'cost_center_id': d.costCenterId,
        'is_default': d.isDefault ? 1 : 0,
        'is_active': d.isActive ? 1 : 0,
        'created_at': d.createdAt.toIso8601String(),
      };

  static CostCenterDimensionCategory _catFromRow(Map<String, Object?> r) {
    return CostCenterDimensionCategory(
      id: r['id'] as String,
      name: r['name'] as String,
      iconName: r['icon_name'] as String?,
      isDefault: (r['is_default'] as int) == 1,
    );
  }

  static Map<String, Object?> _catToRow(CostCenterDimensionCategory c) => {
        'id': c.id,
        'name': c.name,
        'icon_name': c.iconName,
        'is_default': c.isDefault ? 1 : 0,
        'created_at': DateTime.now().toIso8601String(),
      };

  static String _uuid() {
    final r = Random();
    return '${r.nextInt(0xFFFFFFFF).toRadixString(16).padLeft(8, '0')}-'
        '${r.nextInt(0xFFFF).toRadixString(16).padLeft(4, '0')}-'
        '4${r.nextInt(0xFFF).toRadixString(16).padLeft(3, '0')}-'
        '${(r.nextInt(0x3FFF) | 0x8000).toRadixString(16).padLeft(4, '0')}-'
        '${r.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}${r.nextInt(0xFFFFFF).toRadixString(16).padLeft(6, '0')}';
  }
}
