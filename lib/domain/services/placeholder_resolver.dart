/// Replaces `{{token}}` segments using a binding map (unknown keys → empty string).
abstract final class PlaceholderResolver {
  static final RegExp _token = RegExp(r'\{\{\s*(\w+)\s*\}\}');

  static String resolve(String template, Map<String, String> bindings) {
    return template.replaceAllMapped(_token, (m) {
      final key = m.group(1);
      if (key == null) {
        return '';
      }
      return bindings[key] ?? '';
    });
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
