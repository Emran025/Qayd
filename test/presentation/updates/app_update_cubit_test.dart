import 'package:flutter_test/flutter_test.dart';
import 'package:qayd/application/app_updates/check_app_update_use_case.dart';
import 'package:qayd/application/app_updates/install_app_update_use_case.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/app_update_snapshot.dart';
import 'package:qayd/domain/repositories/app_update_repository.dart';
import 'package:qayd/presentation/updates/app_update_cubit.dart';

void main() {
  test('checks for an update and exposes an actionable state', () async {
    final repository = _FakeAppUpdateRepository(
      snapshot: const AppUpdateSnapshot(
        status: AppUpdateStatus.updateAvailable,
        currentPatchNumber: 3,
      ),
    );
    final cubit = AppUpdateCubit(
      checkUpdate: CheckAppUpdateUseCase(repository: repository),
      installUpdate: InstallAppUpdateUseCase(repository: repository),
    );
    addTearDown(cubit.close);

    await cubit.check();

    expect(cubit.state.status, AppUpdateStatus.updateAvailable);
    expect(cubit.state.currentPatchNumber, 3);
    expect(cubit.state.shouldShowBanner, isTrue);
  });

  test('installing an available update changes state to restartRequired', () async {
    final repository = _FakeAppUpdateRepository(
      snapshot: const AppUpdateSnapshot(status: AppUpdateStatus.updateAvailable),
    );
    final cubit = AppUpdateCubit(
      checkUpdate: CheckAppUpdateUseCase(repository: repository),
      installUpdate: InstallAppUpdateUseCase(repository: repository),
    );
    addTearDown(cubit.close);

    await cubit.check();
    await cubit.install();

    expect(repository.installCalls, 1);
    expect(cubit.state.status, AppUpdateStatus.restartRequired);
    expect(cubit.state.isInstalling, isFalse);
  });
}

final class _FakeAppUpdateRepository implements AppUpdateRepository {
  _FakeAppUpdateRepository({required this.snapshot});

  final AppUpdateSnapshot snapshot;
  int installCalls = 0;

  @override
  Future<Result<AppUpdateSnapshot>> checkForUpdate() async => Success(snapshot);

  @override
  Future<Result<void>> installAvailableUpdate() async {
    installCalls++;
    return const Success(null);
  }
}
