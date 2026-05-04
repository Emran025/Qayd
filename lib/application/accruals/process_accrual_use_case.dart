import 'package:qayd/application/vouchers/dtos/create_voucher_input.dart';
import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/domain/repositories/accrual_repository.dart';
import 'package:qayd/application/vouchers/create_voucher_use_case.dart';
import 'package:qayd/domain/value_objects/voucher_type.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


final class ProcessAccrualUseCase {
   ProcessAccrualUseCase(this._repository, this._createVoucherUseCase);

  final AccrualRepository _repository;
  final CreateVoucherUseCase _createVoucherUseCase;

  Future<Result<void>> call(String accrualId, {String? sourceAccountId}) async {
    final res = await _repository.getById(accrualId);
    return res.fold(
      (f) => FailureResult(f),
      (accrual) async {
        if (accrual == null) {
          return  FailureResult(
              ValidationFailure(messageAr: AppStrings.entitlementDoesNotExist));
        }

        final source = sourceAccountId ?? accrual.sourceAccountId;
        if (source == null) {
          return  FailureResult(ValidationFailure(
              messageAr: AppStrings.pleaseSelectTheSource));
        }

        // 1. Create the Voucher
        final voucherResult = await _createVoucherUseCase(CreateVoucherInput(
          type: VoucherType.payment,
          date: DateTime.now(),
          amountMinorUnits: accrual.totalAmountMinor,
          currencyCode: accrual.currencyCode,
          affectedAccountId: source,
          counterpartyAccountId: accrual.destinationAccountId,
          description: 'تنفيذ استحقاق دوري: ${accrual.name}',
          confirm: true,
          costCenterTags: [
            if (accrual.costCenterId != null)
              CostCenterTagInput(
                costCenterId: accrual.costCenterId!,
                dimensionIds:
                    accrual.categoryId != null ? [accrual.categoryId!] : [],
              ),
          ],
        ));

        if (voucherResult.isFailure) {
          return FailureResult(voucherResult.failureOrNull!);
        }

        // 2. Update Accrual Next Due Date
        final nextDate =
            _calculateNextDate(accrual.nextDueDate, accrual.frequency);
        final updated = accrual.copyWith(
          nextDueDate: nextDate,
          isActive: accrual.frequency == AccrualFrequency.once ? false : true,
        );

        return _repository.save(updated);
      },
    );
  }

  DateTime _calculateNextDate(DateTime current, AccrualFrequency frequency) {
    switch (frequency) {
      case AccrualFrequency.daily:
        return current.add(const Duration(days: 1));
      case AccrualFrequency.weekly:
        return current.add(const Duration(days: 7));
      case AccrualFrequency.monthly:
        return DateTime(current.year, current.month + 1, current.day);
      case AccrualFrequency.quarterly:
        return DateTime(current.year, current.month + 3, current.day);
      case AccrualFrequency.semiAnnually:
        return DateTime(current.year, current.month + 6, current.day);
      case AccrualFrequency.yearly:
        return DateTime(current.year + 1, current.month, current.day);
      case AccrualFrequency.once:
        return current;
    }
  }
}
