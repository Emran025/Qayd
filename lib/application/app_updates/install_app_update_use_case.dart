import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/repositories/app_update_repository.dart';

final class InstallAppUpdateUseCase {
  const InstallAppUpdateUseCase({required AppUpdateRepository repository})
      : _repository = repository;

  final AppUpdateRepository _repository;

  Future<Result<void>> call() => _repository.installAvailableUpdate();
}
