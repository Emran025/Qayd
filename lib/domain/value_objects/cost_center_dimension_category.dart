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
  static const spatial = CostCenterDimensionCategory(
    id: 'spatial',
    name: 'بُعد مكاني', // This should still ideally come from a localized source if possible
    iconName: 'location_on',
    isDefault: true,
  );

  static const individual = CostCenterDimensionCategory(
    id: 'individual',
    name: 'بُعد الأفراد',
    iconName: 'people',
    isDefault: true,
  );

  static const project = CostCenterDimensionCategory(
    id: 'project',
    name: 'بُعد المشاريع',
    iconName: 'work',
    isDefault: true,
  );

  @override
  List<Object?> get props => [id, name, iconName, isDefault];
}
