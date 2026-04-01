import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';
import 'package:qayd/domain/value_objects/currency_code.dart';

class AddCurrencyUseCase {
  AddCurrencyUseCase(this._repository);

  final CurrencyRepository _repository;

  Future<Result<void>> call(CurrencyCode currency) {
    return _repository.save(currency, isPredefined: false);
  }
}
