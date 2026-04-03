import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';

abstract interface class TransactionFeeSettingsRepository {
  /// Gets the currently active transaction fee setting, if any.
  Future<Result<TransactionFeeSetting?>> getActive();

  /// Inserts a new transaction fee setting record.
  Future<Result<void>> insert(TransactionFeeSetting setting);

  /// Sets `is_active = false` for all records.
  Future<Result<void>> deactivateAll();
}
