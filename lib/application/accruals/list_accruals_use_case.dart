import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/accrual_component.dart';
import 'package:qayd/domain/repositories/accrual_repository.dart';

final class ListAccrualsUseCase {
  const ListAccrualsUseCase(this._repository);
  final AccrualRepository _repository;

  Future<Result<List<AccrualComponent>>> call() => _repository.getAll();
  
  Future<Result<List<AccrualComponent>>> byCostCenter(String costCenterId) => 
      _repository.getByCostCenter(costCenterId);
}
