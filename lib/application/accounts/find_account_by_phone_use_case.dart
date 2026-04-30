import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/data/services/phone_normalization_service.dart';


class FindAccountByPhoneUseCase {
  FindAccountByPhoneUseCase(this._repository, this._licenseVault);
 
  final AccountRepository _repository;
  final LicenseVault _licenseVault;


  Future<Result<String?>> call(String phone) async {
    try {
      final licenseData = await _licenseVault.readLicenseData();
      final ownerPhone = licenseData?['phone']?.toString() ?? '';
      final normalizer = PhoneNormalizationService(ownerPhone: ownerPhone);
      
      final normalized = normalizer.normalizeDigitsOnly(phone);
      
      final r = await _repository.findAccountByPhone(normalized);
      if (r.isFailure) return FailureResult(r.failureOrNull!);
      return Success(r.valueOrNull?.value);

    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
