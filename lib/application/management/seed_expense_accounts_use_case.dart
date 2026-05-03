import 'package:qayd/application/accounts/create_account_use_case.dart';
import 'package:qayd/application/accounts/dtos/create_account_input.dart';
import 'package:qayd/application/cost_centers/create_cost_center_use_case.dart';
import 'package:qayd/application/cost_centers/manage_dimensions_use_case.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/cost_center.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/cost_center_repository.dart';
import 'package:qayd/domain/value_objects/cost_center_dimension_category.dart';
import 'package:qayd/domain/value_objects/cost_center_type.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';


/// One-time or on-demand service to create aggregate expense accounts
/// based on the predefined cost center dimension categories.
///
/// It also ensures that a 'Personal Life' Cost center exists, and that
/// dimensions for each category are created within it, linking everything
/// together for seamless analytical tracking.
class SeedExpenseAccountsUseCase {
  final AccountRepository _accountRepository;
  final CreateAccountUseCase _createAccountUseCase;
  final CostCenterRepository _costCenterRepository;
  final CreateCostCenterUseCase _createCostCenterUseCase;
  final ManageDimensionsUseCase _manageDimensionsUseCase;

  SeedExpenseAccountsUseCase(
    this._accountRepository,
    this._createAccountUseCase,
    this._costCenterRepository,
    this._createCostCenterUseCase,
    this._manageDimensionsUseCase,
  );

  static const String personalCenterName = AppStringsAr.personalLiving;

  Future<Result<void>> call() async {
    // 1. Ensure 'Personal Life' Cost Center exists
    final centersRes = await _costCenterRepository.getAll(activeOnly: false);
    if (centersRes.isFailure) return centersRes;

    CostCenter? personalCenter = centersRes.valueOrNull!
        .where((c) => c.name == personalCenterName)
        .firstOrNull;

    if (personalCenter == null) {
      final createRes = await _createCostCenterUseCase(
        name: personalCenterName,
        type: CostCenterType.cost,
        currencyCode:
            'SAR', // Fallback, will be updated to base currency in UI if possible
        description: AppStringsAr.aCollectionCenterFor,
      );
      if (createRes.isFailure) return createRes;
      personalCenter = createRes.valueOrNull!;
    }

    // 2. Find the root 'personalExpenses' account
    final accRes = await _accountRepository.getAll(
      activeOnly: false,
    );
    if (accRes.isFailure) return accRes;

    final accounts = accRes.valueOrNull!;
    final root = accounts
        .where((a) =>
            a.isRoot &&
            a.classification.standardKind?.name == 'personalExpenses')
        .firstOrNull;

    if (root == null) {
      return const FailureResult(ValidationFailure(
        messageAr: AppStringsAr.theRootAccountFor,
      ));
    }

    // 3. Get existing dimensions and children for mapping
    final existingDimsRes = await _manageDimensionsUseCase.listDimensions(
      costCenterId: personalCenter.id,
    );
    final existingDims = existingDimsRes.valueOrNull ?? [];

    final existingChildren =
        accounts.where((a) => a.parentId?.value == root.id.value).toList();

    // 4. Seed categories as Dimensions and Accounts
    for (final category in CostCenterDimensionCategory.values) {
      if (category.id == CostCenterDimensionCategory.incomeAndWork.id) {
        continue; // Skip income categories for expense seeding
      }

      // Check/Create Dimension
      var dimension =
          existingDims.where((d) => d.category.id == category.id).firstOrNull;

      if (dimension == null) {
        final dimRes = await _manageDimensionsUseCase.addDimension(
          name: category.name,
          category: category,
          costCenterId: personalCenter.id,
        );
        if (dimRes.isSuccess) {
          dimension = dimRes.valueOrNull!;
        }
      }

      if (dimension == null) continue;

      // Check/Create Account
      final alreadyExists = existingChildren
          .any((a) => a.metadata['linked_dimension_id'] == dimension!.id);

      if (!alreadyExists) {
        await _createAccountUseCase(
          CreateAccountInput(
            name: category.name,
            parentAccountId: root.id.value,
            metadata: {
              'linked_cost_center_id': personalCenter.id,
              'linked_dimension_id': dimension.id,
              'auto_tag_cost_center': true,
              'icon_name': category.iconName,
            },
          ),
        );
      }
    }

    return const Success(null);
  }
}
