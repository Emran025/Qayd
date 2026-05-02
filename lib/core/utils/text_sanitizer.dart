import 'package:flutter/foundation.dart';

/// Utility class to sanitize strings from emojis and unsupported characters
/// to prevent Flutter text rendering engine from throwing font fallback errors.
abstract final class TextSanitizer {
  /// Regular expression to match emojis.
  static final emojiRegex = RegExp(
      r'(\u00a9|\u00ae|[\u2000-\u3300]|\ud83c[\ud000-\udfff]|\ud83d[\ud000-\udfff]|\ud83e[\ud000-\udfff])');

  /// Removes emojis from the given text and logs the action if an emoji was found.
  /// This is particularly useful for names or descriptions that get exported or displayed
  /// and might cause the "Unable to find a font to draw" warning or crash PDF/Excel parsers.
  static String sanitizeText(String input) {
    if (input.isEmpty) return input;

    if (emojiRegex.hasMatch(input)) {
      final sanitized = input.replaceAll(emojiRegex, ' ').trim();
      debugPrint(
        'TextSanitizer: ⚠️ Removed emoji(s) from "$input". \n'
        'Reason: Flutter/PDF/Excel engines might throw "Unable to find a font to draw" '
        'or drop frames when trying to render unsupported emojis without a fallback font.',
      );
      return sanitized;
    }
    return input;
  }

  /// Cleans up exception messages by removing generic HTTP/Dio artifacts
  /// like "DioException" or "bad response" before showing them to the user.
  static String sanitizeErrorMessage(Object e) {
    String msg = e.toString().split('\n').first;

    // Remove variations of DioException and its brackets/colons
    msg = msg.replaceAll(RegExp(r'DioException\s*\[.*?\]:?\s*'), '');
    msg = msg.replaceAll(RegExp(r'DioException:?\s*'), '');

    // Remove specific keywords requested by user
    msg = msg.replaceAll(RegExp(r'(?i)bad\s*response'), '');

    // Clean up any leftover punctuation or spaces at the start
    msg = msg.replaceFirst(RegExp(r'^[\s:]+'), '');

    return msg.trim();
  }
}
