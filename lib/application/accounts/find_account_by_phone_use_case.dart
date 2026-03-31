import 'package:qayd/application/failure_mapping.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/account_repository.dart';

class FindAccountByPhoneUseCase {
  FindAccountByPhoneUseCase(this._repository);

  final AccountRepository _repository;

  Future<Result<String?>> call(String phone) async {
    try {
      final r = await _repository.findAccountByPhone(phone);
      if (r.isFailure) return FailureResult(r.failureOrNull!);
      return Success(r.valueOrNull?.value);
    } catch (e) {
      return FailureResult(failureFromDomainException(e));
    }
  }
}
