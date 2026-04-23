import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

enum WhatsAppFlavor {
  standard('com.whatsapp', 'واتساب'),
  business('com.whatsapp.w4b', 'واتساب للأعمال');

  final String packageName;
  final String displayName;

  const WhatsAppFlavor(this.packageName, this.displayName);
}

/// Opens the platform SMS composer or WhatsApp with pre-filled [text] (offline intent).
abstract final class MessagingIntentLauncher {
  static const MethodChannel _channel = MethodChannel('app.qayd/whatsapp_intent');

  static Future<bool> openSmsWithBody(String text, {String? phoneNumber}) {
    final uriStr = phoneNumber != null && phoneNumber.trim().isNotEmpty
        ? 'sms:+${phoneNumber.trim()}?body=${Uri.encodeComponent(text)}'
        : 'sms:?body=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(uriStr);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  static Future<bool> isPackageInstalled(WhatsAppFlavor flavor) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'checkPackageInstalled',
        {'packageName': flavor.packageName},
      );
      return result ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Uses Native Intent to share to a specific WhatsApp flavor.
  static Future<bool> shareToWhatsApp({
    required WhatsAppFlavor flavor,
    String? phoneNumber,
    String? message,
    String? fileAbsolutePath,
  }) async {
    try {
      String? cleanPhone;
      if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
         cleanPhone = phoneNumber.replaceAll(RegExp(r'[\+\-\(\)\s]'), '');
      }

      await _channel.invokeMethod(
        'shareToWhatsApp',
        {
          'packageName': flavor.packageName,
          'phoneNumber': cleanPhone,
          'message': message,
          'filePath': fileAbsolutePath,
        },
      );
      return true;
    } on PlatformException catch (_) {
      return false;
    }
  }

  /// Legacy fallback for platforms where intents fail or for broad web fallback
  static Future<bool> openWhatsAppWithText(String text, {String? phoneNumber}) {
    String formattedPhone = '';
    if (phoneNumber != null && phoneNumber.trim().isNotEmpty) {
      // Remove +, spaces, -, (, )
      formattedPhone = phoneNumber.replaceAll(RegExp(r'[\+\-\(\)\s]'), '');
    }

    final uriStr = formattedPhone.isNotEmpty
        ? 'https://wa.me/+$formattedPhone?text=${Uri.encodeComponent(text)}'
        : 'https://wa.me/?text=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(
      uriStr,
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
