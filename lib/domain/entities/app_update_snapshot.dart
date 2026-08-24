enum AppUpdateStatus {
  unavailable,
  upToDate,
  updateAvailable,
  restartRequired,
}

final class AppUpdateSnapshot {
  const AppUpdateSnapshot({
    required this.status,
    this.currentPatchNumber,
    this.message,
  });

  final AppUpdateStatus status;
  final int? currentPatchNumber;
  final String? message;
}
