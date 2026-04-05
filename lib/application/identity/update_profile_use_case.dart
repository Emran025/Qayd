import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/application/failure_mapping.dart';

class UpdateProfileUseCase {
  const UpdateProfileUseCase({
    required IdentityRepository identityRepository,
    required LicenseVault licenseVault,
  })  : _identity = identityRepository,
        _license = licenseVault;

  final IdentityRepository _identity;
  final LicenseVault _license;

  Future<Result<void>> call({
    String? name,
    String? phone,
    String? email,
    String? whatsappNumber,
    String? avatarPath,
    String? logoPath,
  }) async {
    try {
      final updatedData = await _identity.updateProfile(
        name: name,
        phone: phone,
        email: email,
        whatsappNumber: whatsappNumber,
        avatarPath: avatarPath,
        logoPath: logoPath,
      );

      // Persist locally in LicenseVault so it reflects across the app.
      await _license.writeLicenseData(updatedData);

      return const Success(null);
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
