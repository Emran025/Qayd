import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:qayd/domain/services/native_notification_service.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';

/// Concrete implementation for Android/iOS local notifications.
class LocalNotificationServiceImpl implements NativeNotificationService {
  final SharedPreferences _prefs;
  LocalNotificationServiceImpl(this._prefs);

  static const _kPeerActivity = 'notif_peer_activity';
  static const _kSelfActivity = 'notif_self_activity';
  static const _kSoundEnabled = 'notif_sound_enabled';
  static const _kVibrationEnabled = 'notif_vibration_enabled';

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
    // Check global preference for peer activity (claims, transfers, etc)
    final allowed = _prefs.getBool(_kPeerActivity) ?? true;
    if (!allowed) return;

    debugPrint('Native IMPORTANT Notification: $title - $body');

    final sound = _prefs.getBool(_kSoundEnabled) ?? true;
    final vibration = _prefs.getBool(_kVibrationEnabled) ?? true;

    final androidDetails = AndroidNotificationDetails(
      'qayd_important_channel',
      AppStringsAr.channelImportantTitle,
      channelDescription: AppStringsAr.channelImportantDesc,
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      color: const Color(0xFFFACC15), // Qayd Gold Accent
      styleInformation: BigTextStyleInformation(
        body,
        contentTitle: title,
        summaryText: AppStringsAr.channelImportantSummary,
      ),
      playSound: sound,
      enableVibration: vibration,
    );

    final iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: sound,
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
    // Local notifications are usually self-activities or background confirmations
    final allowed = _prefs.getBool(_kSelfActivity) ?? true;
    if (!allowed) return;

    debugPrint('Native Local Notification: $title - $body');

    final sound = _prefs.getBool(_kSoundEnabled) ?? true;
    final vibration = _prefs.getBool(_kVibrationEnabled) ?? true;

    final androidDetails = AndroidNotificationDetails(
      'qayd_default_channel',
      AppStringsAr.channelDefaultTitle,
      channelDescription: AppStringsAr.channelDefaultDesc,
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      color: const Color(0xFF1E293B), // Dark Slate
      styleInformation: BigTextStyleInformation(body),
      playSound: sound,
      enableVibration: vibration,
    );

    final iosDetails = DarwinNotificationDetails(
      presentSound: sound,
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
}
