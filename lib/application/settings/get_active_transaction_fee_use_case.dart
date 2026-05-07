import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/entities/transaction_fee_type.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';

class GetActiveTransactionFeeUseCase {
  GetActiveTransactionFeeUseCase(this._repo);

  final TransactionFeeSettingsRepository _repo;

  Future<Result<TransactionFeeSetting?>> call(
      [TransactionFeeType type = TransactionFeeType.tripartite]) async {
    return _repo.getActive(type);
  }
}
