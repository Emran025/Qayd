import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/app_update_snapshot.dart';
import 'package:qayd/domain/repositories/app_update_repository.dart';

final class CheckAppUpdateUseCase {
  const CheckAppUpdateUseCase({required AppUpdateRepository repository})
      : _repository = repository;

  final AppUpdateRepository _repository;

  Future<Result<AppUpdateSnapshot>> call() => _repository.checkForUpdate();
}
