import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/accrual_component.dart';

abstract class AccrualRepository {
  Future<Result<List<AccrualComponent>>> getAll();

  Future<Result<AccrualComponent?>> getById(String id);

  Future<Result<List<AccrualComponent>>> getByCostCenter(String costCenterId);

  Future<Result<List<AccrualComponent>>> getDueAccruals(DateTime at);

  Future<Result<void>> save(AccrualComponent component);

  Future<Result<void>> delete(String id);
}
