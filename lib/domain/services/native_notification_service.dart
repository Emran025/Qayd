abstract interface class NativeNotificationService {
  /// Simple alert with title and body.
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  });

  /// High-priority alert for financial claims/requests.
  Future<void> showImportantNotification({
    required String title,
    required String body,
    String? payload,
  });

  /// Initialize native notification channels and permissions.
  Future<void> initialize();

  /// Stream of payloads emitted when a user taps a notification.
  Stream<String?> get onNotificationTap;
}
