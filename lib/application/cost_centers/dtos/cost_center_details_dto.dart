import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/entities/cost_center_dimension.dart';

/// DTO for cost center details — center entity + dimensions + KPIs.
final class CostCenterDetailsDto {
  const CostCenterDetailsDto({
    required this.center,
    required this.dimensions,
    required this.totalsByCurrency,
    required this.voucherCount,
  });

  final CostCenter center;
  final List<CostCenterDimension> dimensions;

  /// Total confirmed amounts by currency code.
  final Map<String, int> totalsByCurrency;

  final int voucherCount;
}
