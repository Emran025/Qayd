import 'package:flutter/foundation.dart';
import 'package:qayd/domain/repositories/collateral_repository.dart';
import 'package:qayd/domain/services/native_notification_service.dart';
import 'package:qayd/core/result/result.dart';

/// Periodically checks for collaterals approaching or past their
/// expiry date and triggers local notifications.
///
/// Schedule this via [Timer.periodic] from the injection container
/// or an app lifecycle hook.
class CollateralExpiryChecker {
  CollateralExpiryChecker({
    required this.collateralRepository,
    required this.notificationService,
  });

  final CollateralRepository collateralRepository;
  final NativeNotificationService notificationService;

  /// Checks for collaterals expiring within 24 hours and sends alerts.
  Future<void> checkAndNotify() async {
    try {
      final result = await collateralRepository.listExpiring(
        within: const Duration(hours: 24),
      );
      final expiring = result.valueOrNull ?? [];
      for (final c in expiring) {
        await notificationService.showImportantNotification(
          title: 'تنبيه: موعد استحقاق رهن',
          body: 'الرهن "${c.description}" يستحق اليوم',
          payload: 'collateral:${c.id.value}',
        );
      }
    } catch (e) {
      debugPrint('CollateralExpiryChecker error: $e');
    }
  }

  /// Checks for collaterals expiring within 7 days (weekly warning).
  Future<void> checkWeeklyWarnings() async {
    try {
      final result = await collateralRepository.listExpiring(
        within: const Duration(days: 7),
      );
      final expiring = result.valueOrNull ?? [];
      for (final c in expiring) {
        if (c.expiryDate != null) {
          final daysLeft =
              c.expiryDate!.difference(DateTime.now()).inDays;
          if (daysLeft > 1) {
            await notificationService.showLocalNotification(
              title: 'تذكير: رهن يستحق قريباً',
              body: 'الرهن "${c.description}" يستحق خلال $daysLeft يوم',
              payload: 'collateral:${c.id.value}',
            );
          }
        }
      }
    } catch (e) {
      debugPrint('CollateralExpiryChecker weekly error: $e');
    }
  }
}
