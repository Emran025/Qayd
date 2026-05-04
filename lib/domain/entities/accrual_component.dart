import 'package:qayd/presentation/l10n/app_strings.dart';
enum AccrualFrequency {
  daily,
  weekly,
  monthly,
  quarterly,
  semiAnnually,
  yearly,
  once;

  String get labelAr {
    switch (this) {
      case AccrualFrequency.daily:
        return AppStrings.daily;
      case AccrualFrequency.weekly:
        return AppStrings.weekly;
      case AccrualFrequency.monthly:
        return AppStrings.monthly;
      case AccrualFrequency.quarterly:
        return AppStrings.quarterly;
      case AccrualFrequency.semiAnnually:
        return AppStrings.semiannually;
      case AccrualFrequency.yearly:
        return AppStrings.annually;
      case AccrualFrequency.once:
        return AppStrings.once;
    }
  }
}

class AccrualComponent {
  const AccrualComponent({
    required this.id,
    required this.name,
    this.description,
    required this.totalAmountMinor,
    required this.currencyCode,
    this.sourceAccountId,
    required this.destinationAccountId,
    this.costCenterId,
    this.categoryId,
    required this.frequency,
    required this.startDate,
    required this.nextDueDate,
    this.isActive = true,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String? description;
  final int totalAmountMinor;
  final String currencyCode;
  final String? sourceAccountId;
  final String destinationAccountId;
  final String? costCenterId;
  final String? categoryId;
  final AccrualFrequency frequency;
  final DateTime startDate;
  final DateTime nextDueDate;
  final bool isActive;
  final DateTime createdAt;

  double get amount => totalAmountMinor / 100.0;

  AccrualComponent copyWith({
    String? name,
    String? description,
    int? totalAmountMinor,
    String? currencyCode,
    String? sourceAccountId,
    String? destinationAccountId,
    String? costCenterId,
    String? categoryId,
    AccrualFrequency? frequency,
    DateTime? startDate,
    DateTime? nextDueDate,
    bool? isActive,
  }) {
    return AccrualComponent(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      totalAmountMinor: totalAmountMinor ?? this.totalAmountMinor,
      currencyCode: currencyCode ?? this.currencyCode,
      sourceAccountId: sourceAccountId ?? this.sourceAccountId,
      destinationAccountId: destinationAccountId ?? this.destinationAccountId,
      costCenterId: costCenterId ?? this.costCenterId,
      categoryId: categoryId ?? this.categoryId,
      frequency: frequency ?? this.frequency,
      startDate: startDate ?? this.startDate,
      nextDueDate: nextDueDate ?? this.nextDueDate,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
