import 'package:flutter/foundation.dart';
import 'package:qayd/domain/value_objects/collateral_id.dart';

/// Audit trail entry recording a collateral re-evaluation.
///
/// Every time a user changes the estimated value or expiry date,
/// a new [CollateralRevaluation] is persisted to maintain a
/// chronological, tamper-evident log of changes.
@immutable
final class CollateralRevaluation {
  const CollateralRevaluation({
    required this.id,
    required this.collateralId,
    required this.oldValueMinor,
    required this.newValueMinor,
    this.oldExpiryDate,
    this.newExpiryDate,
    required this.reason,
    required this.evaluatedAt,
  });

  /// Unique revaluation entry ID.
  final String id;

  /// The collateral this revaluation belongs to.
  final CollateralId collateralId;

  /// Previous estimated value in minor currency units.
  final int oldValueMinor;

  /// New estimated value in minor currency units.
  final int newValueMinor;

  /// Previous expiry date (null if unchanged or not previously set).
  final DateTime? oldExpiryDate;

  /// New expiry date (null if unchanged).
  final DateTime? newExpiryDate;

  /// User-provided reason for the re-evaluation.
  final String reason;

  /// When this re-evaluation was performed.
  final DateTime evaluatedAt;

  /// Human-readable delta for display: "+500" or "-200".
  int get valueDelta => newValueMinor - oldValueMinor;
}
