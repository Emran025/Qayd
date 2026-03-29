import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

class ListCurrenciesUseCase {
  ListCurrenciesUseCase(this._repository);

  final CurrencyRepository _repository;

  Future<Result<List<CurrencyCode>>> call() {
    return _repository.getAll();
  }
}
