import 'package:qayd/application/accounts/dtos/account_default_cost_center_dto.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

/// Manages the per-account list of default cost-center tags.
///
/// These defaults are automatically pre-populated into the
/// [CostCenterTagSelector] whenever the account is selected on a new voucher.
class ManageAccountDefaultCostCentersUseCase {
  const ManageAccountDefaultCostCentersUseCase(this._accountRepository);

  final AccountRepository _accountRepository;

  /// Lists all default cost-center tags for [accountId].
  Future<Result<List<AccountDefaultCostCenterDto>>> list(
    AccountId accountId,
  ) =>
      _accountRepository.getDefaultCostCenters(accountId);

  /// Adds or updates a default cost-center tag for [accountId].
  Future<Result<void>> save({
    required AccountId accountId,
    required String costCenterId,
    required List<String> dimensionIds,
  }) =>
      _accountRepository.saveDefaultCostCenter(
        accountId: accountId,
        costCenterId: costCenterId,
        dimensionIds: dimensionIds,
      );

  /// Removes a default cost-center tag from [accountId].
  Future<Result<void>> remove({
    required AccountId accountId,
    required String costCenterId,
  }) =>
      _accountRepository.removeDefaultCostCenter(
        accountId: accountId,
        costCenterId: costCenterId,
      );
}
