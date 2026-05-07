import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/entities/transaction_fee_type.dart';

abstract interface class TransactionFeeSettingsRepository {
  /// Gets the currently active transaction fee setting for a specific type, if any.
  Future<Result<TransactionFeeSetting?>> getActive(TransactionFeeType type);

  /// Inserts a new transaction fee setting record.
  Future<Result<void>> insert(TransactionFeeSetting setting);

  /// Sets `is_active = false` for all records of a specific type.
  Future<Result<void>> deactivateAll(TransactionFeeType type);
}
