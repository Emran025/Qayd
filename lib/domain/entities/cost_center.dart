import 'package:qayd/domain/exceptions/immutable_entity_exception.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// A Cost or Profit Center that groups vouchers under a named analytical unit.
///
/// Each center can track its own budget and is identified by a unique [id].
/// Centers are never deleted — they can be suspended (deactivated) only when
/// their balance is zero (enforcement is in the application layer).
class CostCenter {
  const CostCenter._({
    required this.id,
    required this.name,
    required this.type,
    required this.description,
    required this.budgetMinorUnits,
    required this.currencyCode,
    required this.isActive,
    required this.isDefault,
    required this.createdAt,
    required this.suspendedAt,
  });

  final String id;
  final String name;
  final CostCenterType type;
  final String? description;

  /// Optional budget ceiling in currency minor units (0 = no limit).
  final int budgetMinorUnits;
  final String currencyCode;
  final bool isActive;

  /// Whether this is a system-seeded center (cannot be deleted/renamed).
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? suspendedAt;

  // ── Computed ─────────────────────────────────────────────────────────────

  bool get isSuspended => !isActive;
  bool get hasBudget => budgetMinorUnits > 0;

  // ── Factories ─────────────────────────────────────────────────────────────

  factory CostCenter.create({
    required String id,
    required String name,
    required CostCenterType type,
    required String currencyCode,
    required DateTime createdAt,
    String? description,
    int budgetMinorUnits = 0,
    bool isDefault = false,
  }) {
    final n = name.trim();
    if (n.isEmpty) throw ArgumentError('Cost center name is required');
    return CostCenter._(
      id: id,
      name: n,
      type: type,
      description: description,
      budgetMinorUnits: budgetMinorUnits,
      currencyCode: currencyCode,
      isActive: true,
      isDefault: isDefault,
      createdAt: createdAt,
      suspendedAt: null,
    );
  }

  factory CostCenter.restore({
    required String id,
    required String name,
    required CostCenterType type,
    required String currencyCode,
    required bool isActive,
    required bool isDefault,
    required DateTime createdAt,
    String? description,
    int budgetMinorUnits = 0,
    DateTime? suspendedAt,
  }) {
    return CostCenter._(
      id: id,
      name: n(name),
      type: type,
      description: description,
      budgetMinorUnits: budgetMinorUnits,
      currencyCode: currencyCode,
      isActive: isActive,
      isDefault: isDefault,
      createdAt: createdAt,
      suspendedAt: suspendedAt,
    );
  }

  static String n(String raw) => raw.trim();

  // ── Mutations ─────────────────────────────────────────────────────────────

  CostCenter rename(String newName) {
    if (isDefault) {
      throw  ImmutableEntityException(
        messageAr: AppStrings.theNameOfThe,
        code: 'cost_center_rename_default',
      );
    }
    final n = newName.trim();
    if (n.isEmpty) throw ArgumentError('Name required');
    return copyWith(name: n);
  }

  CostCenter updateDescription(String? desc) => copyWith(description: desc);

  CostCenter updateBudget(int minorUnits) {
    if (minorUnits < 0) throw ArgumentError('Budget cannot be negative');
    return copyWith(budgetMinorUnits: minorUnits);
  }

  CostCenter suspend(DateTime at) {
    if (!isActive) return this;
    if (isDefault) {
      throw  ImmutableEntityException(
        messageAr: AppStrings.theDefaultCostCenter1,
        code: 'cost_center_suspend_default',
      );
    }
    return copyWith(isActive: false, suspendedAt: at);
  }

  CostCenter activate() {
    if (isActive) return this;
    return copyWith(isActive: true, clearSuspendedAt: true);
  }

  CostCenter copyWith({
    String? name,
    CostCenterType? type,
    String? description,
    int? budgetMinorUnits,
    String? currencyCode,
    bool? isActive,
    bool? isDefault,
    DateTime? suspendedAt,
    bool clearSuspendedAt = false,
  }) {
    return CostCenter._(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      description: description ?? this.description,
      budgetMinorUnits: budgetMinorUnits ?? this.budgetMinorUnits,
      currencyCode: currencyCode ?? this.currencyCode,
      isActive: isActive ?? this.isActive,
      isDefault: isDefault ?? this.isDefault,
      createdAt: createdAt,
      suspendedAt: clearSuspendedAt ? null : (suspendedAt ?? this.suspendedAt),
    );
  }
}
