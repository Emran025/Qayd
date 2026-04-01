import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/currency_repository.dart';

class ToggleCurrencyStatusUseCase {
  ToggleCurrencyStatusUseCase(this._repository);

  final CurrencyRepository _repository;

  Future<Result<void>> call(String code, bool isActive) {
    return _repository.toggleActiveStatus(code, isActive);
  }
}
