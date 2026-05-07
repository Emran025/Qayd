import 'package:qayd/application/sync/sync_coordinator_service.dart';

class SyncFacade {
  const SyncFacade(this._coordinator);

  final SyncCoordinatorService _coordinator;

  bool get isRunning => _coordinator.isRunning;

  void start() => _coordinator.start();

  void stop() => _coordinator.stop();

  Future<void> forceSync() => _coordinator.forceSync();

  void triggerSync() => _coordinator.triggerSync();
}
