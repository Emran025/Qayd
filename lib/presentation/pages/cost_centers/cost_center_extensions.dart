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
    return name;
  }

  IconData get icon {
    return switch (id) {
      'income_work' => Icons.payments_outlined,
      'housing_living' => Icons.home_outlined,
      'nutrition_consumption' => Icons.restaurant_outlined,
      'transportation' => Icons.directions_car_outlined,
      'health_care' => Icons.medical_services_outlined,
      'education_development' => Icons.school_outlined,
      'family_dependents' => Icons.family_restroom_outlined,
      'obligations_debts' => Icons.account_balance_outlined,
      'investments_projects' => Icons.trending_up_rounded,
      'savings_reserves' => Icons.savings_outlined,
      'entertainment_lifestyle' => Icons.sports_esports_outlined,
      _ => Icons.category_outlined,
    };
  }
}
