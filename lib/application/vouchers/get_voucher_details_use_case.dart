import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_input.dart';
import 'package:qayd/application/vouchers/dtos/get_voucher_details_output.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/voucher_repository.dart';
import 'package:qayd/domain/services/voucher_qr_service.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/voucher_id.dart';

class GetVoucherDetailsUseCase {
  GetVoucherDetailsUseCase(
    this._voucherRepository,
    this._accountRepository,
    this._qrService,
  );

  final VoucherRepository _voucherRepository;
  final AccountRepository _accountRepository;
  final VoucherQrService _qrService;

  Future<Result<GetVoucherDetailsOutput>> call(
    GetVoucherDetailsInput input,
  ) async {
    try {
      final vR = await _voucherRepository.getById(VoucherId(input.voucherId));
      if (vR.isFailure) {
        return FailureResult(vR.failureOrNull!);
      }
      final v = vR.valueOrNull!;

      Future<String> nameFor(AccountId id) async {
        final r = await _accountRepository.getById(id);
        if (r.isSuccess) {
          return r.valueOrNull!.name;
        }
        return id.value;
      }

      final counterpartyName = await nameFor(v.counterpartyId);
      final affectedName = await nameFor(v.affectedAccountId);

      return Success(
        GetVoucherDetailsOutput(
          id: v.id.value,
          typeCode: v.type.name,
          stateCode: v.state.name,
          dateIso: v.date.toIso8601String(),
          amountMinorUnits: v.amount.minorUnits,
          currencyCode: v.currency.code,
          currencyNameAr: v.currency.nameAr,
          currencySymbol: v.currency.symbol,
          currencyDigits: v.currency.fractionalDigits,
          counterpartyAccountId: v.counterpartyId.value,
          counterpartyName: counterpartyName,
          affectedAccountId: v.affectedAccountId.value,
          affectedName: affectedName,
          referenceNumber: v.referenceNumber,
          description: v.description,
          notes: v.notes,
          qrData: _qrService.generateQrData(v),
          createdAtIso: v.createdAt.toIso8601String(),
          confirmedAtIso: v.confirmedAt?.toIso8601String(),
          settledAtIso: v.settledAt?.toIso8601String(),
        ),
      );
    } catch (e, _) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
