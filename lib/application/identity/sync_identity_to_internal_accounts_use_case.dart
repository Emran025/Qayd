import 'package:qayd/core/result/result.dart';
import 'package:qayd/data/security/license_vault.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/value_objects/standard_account_classification_kind.dart';

/// Ensures that internal root accounts (Fund, Expenses, Revenues, Transfers)
/// are linked to the user's own identity details (phone, name, etc.) stored in the license vault.
///
/// This facilitates consistent voucher exports and detail previews where the user
/// is technically the counterparty to their own internal transactions.
class SyncIdentityToInternalAccountsUseCase {
  const SyncIdentityToInternalAccountsUseCase({
    required AccountRepository accountRepository,
    required LicenseVault licenseVault,
  })  : _accountRepository = accountRepository,
        _licenseVault = licenseVault;

  final AccountRepository _accountRepository;
  final LicenseVault _licenseVault;

  Future<Result<void>> call() async {
    try {
      final licenseData = await _licenseVault.readLicenseData();
      if (licenseData == null) return const Success(null);

      final phone = licenseData['phone'] as String?;
      final email = licenseData['email'] as String?;
      final serverId = (licenseData['id'] as num?)?.toInt();

      if (phone == null || phone.isEmpty) return const Success(null);

      final accountsResult = await _accountRepository.getAll();
      if (accountsResult.isFailure)
        {return FailureResult(accountsResult.failureOrNull!);}

      final accounts = accountsResult.valueOrNull!;
      final internalKinds = [
        StandardAccountClassificationKind.liquidAssets,
        StandardAccountClassificationKind.personalExpenses,
        StandardAccountClassificationKind.personalRevenues,
        StandardAccountClassificationKind.clearingRemittances,
      ];

      final internalRoots = accounts
          .where((a) =>
              a.isRoot &&
              a.classification.standardKind != null &&
              internalKinds.contains(a.classification.standardKind))
          .toList();

      for (final account in internalRoots) {
        // We upsert party details for each internal root to match user identity
        final details = PartyDetails(
          accountId: account.id,
          phoneNumber: phone,
          email: email,
          partyType: 'Owner', // Semantic label for internal accounts
          serverAccountId: serverId,
        );
        await _accountRepository.savePartyDetails(details);
      }

      return const Success(null);
    } catch (e) {
      return const Success(null); // Silent fail to not block app boot
    }
  }
}
