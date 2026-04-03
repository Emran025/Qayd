import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/core/utils/id_generator.dart';
import 'package:qayd/domain/entities/transaction_fee_setting.dart';
import 'package:qayd/domain/repositories/transaction_fee_settings_repository.dart';

class ManageTransactionFeeUseCase {
  ManageTransactionFeeUseCase(this._repo, this._idGen);

  final TransactionFeeSettingsRepository _repo;
  final IdGenerator _idGen;

  /// Enables a transaction fee by deactivating all old ones and appending a new one.
  Future<Result<void>> enableFee({
    required int amountMinorUnits,
    required String currencyCode,
  }) async {
    try {
      final deactivateRes = await _repo.deactivateAll();
      if (deactivateRes.isFailure) {
        return FailureResult(deactivateRes.failureOrNull!);
      }

      final setting = TransactionFeeSetting(
        id: _idGen.next(),
        amountMinorUnits: amountMinorUnits,
        currencyCode: currencyCode,
        isActive: true,
        createdAt: DateTime.now(),
      );

      return await _repo.insert(setting);
    } catch (e) {
      return FailureResult(ValidationFailure(messageAr: 'فشل في تفعيل الرسوم: \$e'));
    }
  }

  /// Disables the transaction fee globally.
  Future<Result<void>> disableFee() async {
    try {
      return await _repo.deactivateAll();
    } catch (e) {
      return FailureResult(ValidationFailure(messageAr: 'فشل في تعطيل الرسوم: \$e'));
    }
  }
}
