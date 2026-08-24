import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/app_update_snapshot.dart';
import 'package:qayd/domain/repositories/app_update_repository.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';

final class ShorebirdAppUpdateRepository implements AppUpdateRepository {
  ShorebirdAppUpdateRepository({ShorebirdUpdater? updater})
      : _updater = updater ?? ShorebirdUpdater();

  final ShorebirdUpdater _updater;

  @override
  Future<Result<AppUpdateSnapshot>> checkForUpdate() async {
    if (!_updater.isAvailable) {
      return const Success(
        AppUpdateSnapshot(status: AppUpdateStatus.unavailable),
      );
    }

    try {
      final status = await _updater.checkForUpdate();
      final currentPatch = await _updater.readCurrentPatch();
      return Success(
        AppUpdateSnapshot(
          status: switch (status) {
            UpdateStatus.upToDate => AppUpdateStatus.upToDate,
            UpdateStatus.outdated => AppUpdateStatus.updateAvailable,
            UpdateStatus.restartRequired => AppUpdateStatus.restartRequired,
            UpdateStatus.unavailable => AppUpdateStatus.unavailable,
          },
          currentPatchNumber: currentPatch?.number,
        ),
      );
    } on ReadPatchException catch (error) {
      return FailureResult(
        UnexpectedFailure(messageAr: 'تعذر قراءة حالة تحديث التطبيق: $error'),
      );
    } catch (error) {
      return FailureResult(
        NetworkFailure(messageAr: 'تعذر التحقق من وجود تحديث حالياً: $error'),
      );
    }
  }

  @override
  Future<Result<void>> installAvailableUpdate() async {
    if (!_updater.isAvailable) {
      return const FailureResult(
        ValidationFailure(
            messageAr: 'تحديثات التطبيق غير متاحة في هذا البناء.'),
      );
    }

    try {
      await _updater.update();
      return const Success(null);
    } on UpdateException catch (error) {
      return FailureResult(
        NetworkFailure(messageAr: 'تعذر تنزيل تحديث التطبيق: ${error.message}'),
      );
    } catch (error) {
      return FailureResult(
        NetworkFailure(messageAr: 'تعذر تنزيل تحديث التطبيق: $error'),
      );
    }
  }
}
