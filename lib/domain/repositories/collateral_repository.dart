import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/collateral.dart';
import 'package:qayd/domain/entities/collateral_revaluation.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';
import 'package:qayd/domain/value_objects/collateral_status.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

/// Repository contract for collateral persistence and audit trail.
abstract interface class CollateralRepository {
  /// Returns the collateral linked to a voucher (1:1 relationship), or null.
  Future<Result<Collateral?>> getByVoucherId(VoucherId voucherId);

  /// Returns a collateral by its own ID.
  Future<Result<Collateral>> getById(CollateralId id);

  /// Persists a new collateral record.
  Future<Result<void>> save(Collateral collateral);

  /// Updates an existing collateral record.
  Future<Result<void>> update(Collateral collateral);

  /// Returns collaterals whose expiry date falls within [within] from now.
  Future<Result<List<Collateral>>> listExpiring({required Duration within});

  /// Returns all collaterals of a given status (e.g. active, expired).
  Future<Result<List<Collateral>>> listByStatus(CollateralStatus status);

  // ── Audit Trail ─────────────────────────────────────────────────────────

  /// Persists a re-evaluation log entry.
  Future<Result<void>> saveRevaluation(CollateralRevaluation entry);

  /// Returns the full re-evaluation history for a collateral, chronologically.
  Future<Result<List<CollateralRevaluation>>> getRevaluationHistory(
    CollateralId id,
  );
  
  /// Returns a set of voucher IDs that have associated collateral from the given list.
  Future<Result<Set<String>>> getVoucherIdsWithCollateral(List<VoucherId> voucherIds);
}
