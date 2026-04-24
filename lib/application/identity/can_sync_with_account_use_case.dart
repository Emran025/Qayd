import 'package:qayd/domain/repositories/account_repository.dart';
import 'package:qayd/domain/repositories/identity_repository.dart';
import 'package:qayd/domain/value_objects/account_id.dart';
import 'package:qayd/domain/value_objects/sync_privacy_policy.dart';
import 'package:qayd/core/result/result.dart';

/// Evaluates if synchronization is allowed with a specific account based on
/// the global privacy policy and any local/remote overrides.
class CanSyncWithAccountUseCase {
  const CanSyncWithAccountUseCase({
    required IdentityRepository identityRepository,
    required AccountRepository accountRepository,
  })  : _identityRepo = identityRepository,
        _accountRepo = accountRepository;

  final IdentityRepository _identityRepo;
  final AccountRepository _accountRepo;

  Future<bool> call(AccountId accountId) async {
    // 1. Get the account and its phone number
    final accountResult = await _accountRepo.getById(accountId);
    if (accountResult.isFailure) return false;
    final account = accountResult.valueOrNull!;

    final partyResult = await _accountRepo.getPartyDetails(accountId);
    final phone = partyResult.valueOrNull?.phoneNumber;

    // 2. Get current privacy policy
    // Note: In a production environment, this should ideally be cached
    // to avoid redundant network calls during high-frequency sync.
    final policy = await _identityRepo.getSyncPolicy();

    // 3. Local-only metadata override (for accounts without phones or forced overrides)
    final localPrivacy = account.metadata['sync_privacy'] as String?;

    // 4. Global Policy Logic
    switch (policy.mode) {
      case SyncPolicyMode.open:
        return true;

      case SyncPolicyMode.closed:
        return false;

      case SyncPolicyMode.openToContacts:
        // Allowed if this account exists in our local chart of accounts.
        return true;

      case SyncPolicyMode.openWithBlocklist:
        if (localPrivacy == 'block') return false;
        if (phone != null && phone.trim().isNotEmpty) {
          final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
          final isBlocked = policy.blockList.any(
              (e) => e.targetPhone.replaceAll(RegExp(r'\s+'), '') == cleaned);
          return !isBlocked;
        }
        return true; // No phone and no local block = not blocked

      case SyncPolicyMode.closedWithAllowlist:
        if (localPrivacy == 'allow') return true;
        if (phone != null && phone.trim().isNotEmpty) {
          final cleaned = phone.replaceAll(RegExp(r'\s+'), '');
          final isAllowed = policy.allowList.any(
              (e) => e.targetPhone.replaceAll(RegExp(r'\s+'), '') == cleaned);
          return isAllowed;
        }
        return false; // No phone and no local allow = not allowed
    }
  }
}
