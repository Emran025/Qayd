import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';

class GetBaseCurrencyUseCase {
  GetBaseCurrencyUseCase(this._repository);

  final CurrencyRepository _repository;

  Future<Result<String>> call() {
    return _repository.getBaseCurrencyCode();
  }
}
