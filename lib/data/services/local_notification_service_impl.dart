import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:qayd/domain/services/native_notification_service.dart';

/// Concrete implementation for Android/iOS local notifications.
class LocalNotificationServiceImpl implements NativeNotificationService {
  LocalNotificationServiceImpl();

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<String?>.broadcast();

  @override
  Stream<String?> get onNotificationTap => _tapController.stream;

  @override
  Future<void> initialize() async {
    debugPrint('Initializing Native Notifications...');

    // Request permission (Android 13+ requires this dynamically)
    if (!kIsWeb) {
      await Permission.notification.request();
    }

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _plugin.initialize(
      settings : initializationSettings,
      onDidReceiveNotificationResponse: (response) {
        debugPrint('Notification tapped: ${response.payload}');
        _tapController.add(response.payload);
      },
    );
  }

  /// Generates a relatively unique ID for notifications.
  int _nextId() => DateTime.now().millisecondsSinceEpoch.remainder(100000);

  @override
  Future<void> showImportantNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Native IMPORTANT Notification: $title - $body');

    final androidDetails = AndroidNotificationDetails(
      'qayd_important_channel',
      'إشعارات قيد الهامة',
      channelDescription: 'تنبيهات الحوالات والسندات المباشرة',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: const Color(0xFFFACC15), // Qayd Gold Accent
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: 'تنبيه مالي',
      ),
      playSound: true,
      enableVibration: true,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      interruptionLevel: InterruptionLevel.timeSensitive,
    );

    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      id: _nextId(),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }

  @override
  Future<void> showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    debugPrint('Native Local Notification: $title - $body');

    final androidDetails = AndroidNotificationDetails(
      'qayd_default_channel',
      'إشعارات قيد العامة',
      channelDescription: 'تحديثات النظام والمزامنة في الخلفية',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: const Color(0xFF1E293B), // Dark Slate
      styleInformation: BigTextStyleInformation(body),
    );

    const iosDetails = DarwinNotificationDetails();
    final details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.show(
      id: _nextId(),
      title: title,
      body: body,
      notificationDetails: details,
      payload: payload,
    );
  }
}


