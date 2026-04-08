import 'package:equatable/equatable.dart';

/// An analytical classification/category for dimensions (e.g. "Spatial", "Individual").
/// Formerly a static enum, now a dynamic entity to allow user customization.
class CostCenterDimensionCategory extends Equatable {
  const CostCenterDimensionCategory({
    required this.id,
    required this.name,
    this.iconName,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final String? iconName;
  final bool isDefault;

  // Preserve the static constants for known default categories to maintain 
  // compatibility with parts of the code that expect specific 'spatial' or 'individual' logic.

  static const incomeAndWork = CostCenterDimensionCategory(
    id: 'income_work',
    name: 'الدخل والعمل',
    iconName: 'payments',
    isDefault: true,
  );

  static const housingAndLiving = CostCenterDimensionCategory(
    id: 'housing_living',
    name: 'السكن والمعيشة',
    iconName: 'home',
    isDefault: true,
  );

  static const nutritionAndConsumption = CostCenterDimensionCategory(
    id: 'nutrition_consumption',
    name: 'التغذية والاستهلاك اليومي',
    iconName: 'restaurant',
    isDefault: true,
  );

  static const transportation = CostCenterDimensionCategory(
    id: 'transportation',
    name: 'النقل والتنقل',
    iconName: 'directions_car',
    isDefault: true,
  );

  static const healthAndPersonalCare = CostCenterDimensionCategory(
    id: 'health_care',
    name: 'الصحة والعناية الشخصية',
    iconName: 'medical_services',
    isDefault: true,
  );

  static const educationAndDevelopment = CostCenterDimensionCategory(
    id: 'education_development',
    name: 'التعليم وتنمية القدرات',
    iconName: 'school',
    isDefault: true,
  );

  static const familyAndDependents = CostCenterDimensionCategory(
    id: 'family_dependents',
    name: 'الأسرة والمعالون',
    iconName: 'family_restroom',
    isDefault: true,
  );

  static const obligationsAndDebts = CostCenterDimensionCategory(
    id: 'obligations_debts',
    name: 'الالتزامات والديون',
    iconName: 'account_balance',
    isDefault: true,
  );

  static const investmentsAndProjects = CostCenterDimensionCategory(
    id: 'investments_projects',
    name: 'الاستثمارات والمشاريع',
    iconName: 'trending_up',
    isDefault: true,
  );

  static const savingsAndReserves = CostCenterDimensionCategory(
    id: 'savings_reserves',
    name: 'الادخار وبناء الاحتياطي',
    iconName: 'savings',
    isDefault: true,
  );

  static const entertainmentAndLifestyle = CostCenterDimensionCategory(
    id: 'entertainment_lifestyle',
    name: 'الترفيه ونمط الحياة',
    iconName: 'sports_esports',
    isDefault: true,
  );

  static const List<CostCenterDimensionCategory> values = [
    incomeAndWork,
    housingAndLiving,
    nutritionAndConsumption,
    transportation,
    healthAndPersonalCare,
    educationAndDevelopment,
    familyAndDependents,
    obligationsAndDebts,
    investmentsAndProjects,
    savingsAndReserves,
    entertainmentAndLifestyle,
  ];

  @override
  List<Object?> get props => [id, name, iconName, isDefault];
}
