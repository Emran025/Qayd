import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/account.dart';
import 'package:qayd/domain/value_objects/account_id.dart';

/// Persistence port for the chart of accounts.
abstract interface class AccountRepository {
  Future<Result<Account>> getById(AccountId id);

  Future<Result<List<Account>>> getAll({bool activeOnly = false});

  Future<Result<List<Account>>> getChildrenOf(AccountId parentId);

  Future<Result<List<Account>>> getDescendantsOf(AccountId parentId);

  Future<Result<void>> save(Account account);

  Future<Result<void>> createBatch(List<Account> accounts);

  Future<Result<void>> delete(AccountId id);

  Future<Result<bool>> exists(AccountId id);
}
