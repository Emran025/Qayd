import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/entities/party_details.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

/// Persistence port for the chart of accounts.
abstract interface class AccountRepository {
  Future<Result<Account>> getById(AccountId id);

  Future<Result<List<Account>>> getAll({
    bool activeOnly = false,
    bool excludeArchived = false,
  });

  Future<Result<List<Account>>> getChildrenOf(AccountId parentId);

  Future<Result<List<Account>>> getDescendantsOf(AccountId parentId);

  Future<Result<void>> save(Account account);

  Future<Result<void>> createBatch(List<Account> accounts);

  Future<Result<void>> delete(AccountId id);

  Future<Result<bool>> exists(AccountId id);

  Future<Result<void>> savePartyDetails(PartyDetails details);

  Future<Result<PartyDetails?>> getPartyDetails(AccountId id);

  Future<Result<AccountId?>> findAccountByPhone(String phone);

  Future<Result<AccountId?>> findAccountByEmail(String email);

  Future<Result<AccountId?>> findAccountByWhatsApp(String whatsapp);

  Future<Result<bool>> hasAnyAccounts();

  // ── Archive operations ──────────────────────────────────────────────────

  /// Marks an account as archived. The caller must have already validated
  /// that the account balance is zero before calling this method.
  Future<Result<void>> archiveAccount(AccountId id);

  /// Restores a previously archived account to active status.
  Future<Result<void>> restoreAccount(AccountId id);

  /// Returns only accounts where `is_archived == 1`.
  Future<Result<List<Account>>> getArchivedAccounts();
}
