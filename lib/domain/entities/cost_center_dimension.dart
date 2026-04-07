import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';

/// An analytical dimension tag (e.g. "Home", "Health", "Project A").
///
/// Dimensions are multi-axis classifiers attached to vouchers so cost/profit
/// centers can be sliced by Space, Individual, or Project perspectives.
class CostCenterDimension {
  const CostCenterDimension({
    required this.id,
    required this.name,
    required this.category,
    required this.costCenterId,
    required this.isDefault,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final CostCenterDimensionCategory category;

  /// Owning cost center (null = global / cross-center dimension).
  final String? costCenterId;

  /// Whether this is a pre-seeded system dimension.
  final bool isDefault;
  final bool isActive;
  final DateTime createdAt;
}
