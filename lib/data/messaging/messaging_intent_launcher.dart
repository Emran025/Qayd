import 'package:url_launcher/url_launcher.dart';

/// Opens the platform SMS composer or WhatsApp with pre-filled [text] (offline intent).
abstract final class MessagingIntentLauncher {
  static Future<bool> openSmsWithBody(String text) {
    final uri = Uri.parse('sms:?body=${Uri.encodeComponent(text)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  /// Uses the universal WhatsApp link scheme (no phone required for paste flow).
  static Future<bool> openWhatsAppWithText(String text) {
    final uri = Uri.parse(
      'https://wa.me/?text=${Uri.encodeComponent(text)}',
    );
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
