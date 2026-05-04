/// Replaces `{{token}}` segments using a binding map (unknown keys → empty string).
abstract final class PlaceholderResolver {
  static final RegExp _token = RegExp(r'\{\{\s*(\w+)\s*\}\}');

  static String resolve(String template, Map<String, String> bindings) {
    // Unescape literal \n and other sequences from DB
    final unescapedTemplate = _unescape(template);

    return unescapedTemplate.replaceAllMapped(_token, (m) {
      final key = m.group(1);
      if (key == null) {
        return '';
      }
      return bindings[key] ?? '';
    });
  }

  static String _unescape(String input) {
    return input
        .replaceAll('\\n', '\n')
        .replaceAll('\\r', '\r')
        .replaceAll('\\t', '\t')
        .replaceAllMapped(RegExp(r'\\u([0-9a-fA-F]{4})'), (match) {
      return String.fromCharCode(int.parse(match.group(1)!, radix: 16));
    }).replaceAll('\\\\', '\\');
  }

  /// Placeholder names found in [template] (unique, order not preserved).
  static Set<String> extractKeys(String template) {
    return _token
        .allMatches(template)
        .map((m) => m.group(1))
        .whereType<String>()
        .toSet();
  }
}
