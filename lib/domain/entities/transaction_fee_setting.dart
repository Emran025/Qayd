import 'package:qayd/domain/value_objects/money.dart';

class TransactionFeeSetting {
  const TransactionFeeSetting({
    required this.id,
    required this.amountMinorUnits,
    required this.currencyCode,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final int amountMinorUnits;
  final String currencyCode;
  final bool isActive;
  final DateTime createdAt;

  Money? get money {
    // Return money amount, we need to lookup currency or use standard
    // Simplest way is to keep amountMinorUnits and currencyCode as primitives here
    return null;
  }
}
