import 'dart:convert';

class DocumentClause {
  final String title;
  final List<String> details;

  const DocumentClause({
    required this.title,
    required this.details,
  });

  factory DocumentClause.fromJson(Map<String, dynamic> json) {
    return DocumentClause(
      title: json['title'] as String,
      details: (json['details'] as List<dynamic>).map((e) => e as String).toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'details': details,
    };
  }
}

class AppDocument {
  final String type;
  /// If the API hasn't updated its seeder, it might return a plain string.
  /// we keep `content` just in case, but rely mostly on `clauses` which parses
  /// structured JSON.
  final String content; 
  final List<DocumentClause> clauses;
  final String version;

  const AppDocument({
    required this.type,
    required this.content,
    required this.clauses,
    required this.version,
  });

  factory AppDocument.fromJson(Map<String, dynamic> json) {
    String rawContent = json['content'] as String? ?? '';
    List<DocumentClause> parsedClauses = [];

    // Try parsing content as JSON array of clauses
    try {
      final decodedList = jsonDecode(rawContent);
      if (decodedList is List) {
        parsedClauses = decodedList.map((e) => DocumentClause.fromJson(e as Map<String, dynamic>)).toList();
      }
    } catch (_) {
      // If parsing fails, it's just raw text format.
    }

    return AppDocument(
      type: json['type'] as String,
      content: rawContent,
      clauses: parsedClauses,
      version: json['version'] as String? ?? '1.0.0',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'content': content,
      'version': version,
    };
  }
}
