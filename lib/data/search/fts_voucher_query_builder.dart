/// Builds a safe FTS5 [MATCH] expression for [vouchers_fts.body] (prefix per token).
abstract final class FtsVoucherQueryBuilder {
  /// Returns null when [raw] has no searchable tokens.
  static String? matchExpression(String raw) {
    final tokens = raw
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty)
        .toList(growable: false);
    if (tokens.isEmpty) {
      return null;
    }
    final clauses = <String>[];
    for (final t in tokens) {
      final esc = t.replaceAll('"', '""');
      clauses.add('"$esc"*');
    }
    return clauses.join(' AND ');
  }
}
