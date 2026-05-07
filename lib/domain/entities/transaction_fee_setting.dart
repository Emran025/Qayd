import 'package:qayd/domain/entities/fee_calculation_type.dart';
import 'package:qayd/domain/entities/transaction_fee_type.dart';

class TransactionFeeSetting {
  const TransactionFeeSetting({
    required this.id,
    required this.value, // Fixed amount or percentage * 100
    required this.calculationType,
    required this.isActive,
    required this.type,
    required this.createdAt,
  });

  final String id;
  
  /// The value of the fee.
  /// If [calculationType] is [FeeCalculationType.fixed], this is the amount in minor units.
  /// If [calculationType] is [FeeCalculationType.percentage], this is the percentage * 100 (e.g., 150 = 1.5%).
  final int value;

  final FeeCalculationType calculationType;
  final bool isActive;
  final TransactionFeeType type;
  final DateTime createdAt;
}
