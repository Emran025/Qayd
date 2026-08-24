import 'package:qayd/core/result/result.dart';
import 'package:qayd/domain/entities/app_update_snapshot.dart';

abstract interface class AppUpdateRepository {
  Future<Result<AppUpdateSnapshot>> checkForUpdate();

  Future<Result<void>> installAvailableUpdate();
}
