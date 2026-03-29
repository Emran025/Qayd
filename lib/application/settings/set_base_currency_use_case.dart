import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';

class SetBaseCurrencyUseCase {
  SetBaseCurrencyUseCase(this._repository);

  final CurrencyRepository _repository;

  Future<Result<void>> call(String code) {
    return _repository.setBaseCurrencyCode(code);
  }
}
