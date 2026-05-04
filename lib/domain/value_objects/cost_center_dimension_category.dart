import 'package:equatable/equatable.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


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

  static CostCenterDimensionCategory get incomeAndWork => CostCenterDimensionCategory(
        id: 'income_work',
        name: AppStrings.incomeAndWork,
        iconName: 'payments',
        isDefault: true,
      );

  static CostCenterDimensionCategory get housingAndLiving => CostCenterDimensionCategory(
        id: 'housing_living',
        name: AppStrings.housingAndLiving,
        iconName: 'home',
        isDefault: true,
      );

  static CostCenterDimensionCategory get nutritionAndConsumption =>
      CostCenterDimensionCategory(
        id: 'nutrition_consumption',
        name: AppStrings.nutritionAndDailyConsumption,
        iconName: 'restaurant',
        isDefault: true,
      );

  static CostCenterDimensionCategory get transportation =>
      CostCenterDimensionCategory(
        id: 'transportation',
        name: AppStrings.transportationAndMobility,
        iconName: 'directions_car',
        isDefault: true,
      );

  static CostCenterDimensionCategory get healthAndPersonalCare =>
      CostCenterDimensionCategory(
        id: 'health_care',
        name: AppStrings.healthAndPersonalCare,
        iconName: 'medical_services',
        isDefault: true,
      );

  static CostCenterDimensionCategory get educationAndDevelopment =>
      CostCenterDimensionCategory(
        id: 'education_development',
        name: AppStrings.autostring2,
        iconName: 'school',
        isDefault: true,
      );

  static CostCenterDimensionCategory get familyAndDependents =>
      CostCenterDimensionCategory(
        id: 'family_dependents',
        name: AppStrings.familyAndDependents,
        iconName: 'family_restroom',
        isDefault: true,
      );

  static CostCenterDimensionCategory get obligationsAndDebts =>
      CostCenterDimensionCategory(
        id: 'obligations_debts',
        name: AppStrings.obligationsAndDebts1,
        iconName: 'account_balance',
        isDefault: true,
      );

  static CostCenterDimensionCategory get investmentsAndProjects =>
      CostCenterDimensionCategory(
        id: 'investments_projects',
        name: AppStrings.investmentsAndProjects,
        iconName: 'trending_up',
        isDefault: true,
      );

  static CostCenterDimensionCategory get savingsAndReserves =>
      CostCenterDimensionCategory(
        id: 'savings_reserves',
        name: AppStrings.savingAndBuildingReserves,
        iconName: 'savings',
        isDefault: true,
      );

  static CostCenterDimensionCategory get entertainmentAndLifestyle =>
      CostCenterDimensionCategory(
        id: 'entertainment_lifestyle',
        name: AppStrings.entertainmentAndLifestyle,
        iconName: 'sports_esports',
        isDefault: true,
      );

  static List<CostCenterDimensionCategory> get values => [
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
