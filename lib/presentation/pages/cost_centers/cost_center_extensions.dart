import 'package:flutter/material.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

extension CostCenterTypeLabel on CostCenterType {
  String get labelAr {
    return switch (this) {
      CostCenterType.cost => AppStringsAr.costCenterTypeCost,
      CostCenterType.profit => AppStringsAr.costCenterTypeProfit,
    };
  }

  IconData get icon {
    return switch (this) {
      CostCenterType.cost => Icons.pie_chart_rounded,
      CostCenterType.profit => Icons.trending_up_rounded,
    };
  }
}

extension CostCenterDimensionCategoryLabel on CostCenterDimensionCategory {
  String get labelAr {
    // If it's a default category ID, we can still use the centralized localized strings.
    if (id == 'spatial') return AppStringsAr.dimCategorySpatial;
    if (id == 'individual') return AppStringsAr.dimCategoryIndividual;
    if (id == 'project') return AppStringsAr.dimCategoryProject;
    return name;
  }

  IconData get icon {
    return switch (id) {
      'spatial' => Icons.location_on_outlined,
      'individual' => Icons.people_outline_rounded,
      'project' => Icons.work_outline_rounded,
      _ => Icons.category_outlined,
    };
  }
}
