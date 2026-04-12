import 'package:url_launcher/url_launcher.dart';

/// Opens the platform SMS composer or WhatsApp with pre-filled [text] (offline intent).
abstract final class MessagingIntentLauncher {
  static Future<bool> openSmsWithBody(String text, {String? phoneNumber}) {
    final uriStr = phoneNumber != null && phoneNumber.trim().isNotEmpty
        ? 'sms:+${phoneNumber.trim()}?body=${Uri.encodeComponent(text)}'
        : 'sms:?body=${Uri.encodeComponent(text)}';
    final uri = Uri.parse(uriStr);
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Uses the universal WhatsApp link scheme.
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
