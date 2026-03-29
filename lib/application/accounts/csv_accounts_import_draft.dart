import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';

/// Parsed CSV row for future account import (no persistence yet).
class CsvAccountImportDraftRow {
  const CsvAccountImportDraftRow({
    required this.lineNumber,
    required this.name,
    this.natureHint,
  });

  final int lineNumber;
  final String name;
  final String? natureHint;
}

/// Minimal CSV parser: expects a header with `name` / `اسم` and optional `nature` / `طبيعة`.
abstract final class CsvAccountsImportDraft {
  static Result<List<CsvAccountImportDraftRow>> parse(String csvText) {
    final lines = csvText.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          messageAr: 'الملف فارغ.',
          code: 'csv_empty',
        ),
      );
    }
    final header = _splitCsvLine(lines.first);
    final nameIdx = _indexOfName(header);
    if (nameIdx < 0) {
      return const FailureResult(
        ValidationFailure(
          messageAr: 'يجب أن يحتوي الصف الأول على عمود باسم «name» أو «اسم».',
          code: 'csv_header',
        ),
      );
    }
    final natureIdx = _indexOfNature(header);
    final out = <CsvAccountImportDraftRow>[];
    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;
      final cells = _splitCsvLine(line);
      if (nameIdx >= cells.length) continue;
      final name = cells[nameIdx].trim();
      if (name.isEmpty) continue;
      String? nature;
      if (natureIdx >= 0 && natureIdx < cells.length) {
        final n = cells[natureIdx].trim();
        if (n.isNotEmpty) nature = n;
      }
      out.add(
        CsvAccountImportDraftRow(
          lineNumber: i + 1,
          name: name,
          natureHint: nature,
        ),
      );
    }
    if (out.isEmpty) {
      return const FailureResult(
        ValidationFailure(
          messageAr: 'لم يُعثر على صفوف بيانات صالحة.',
          code: 'csv_rows',
        ),
      );
    }
    return Success(out);
  }

  static List<String> _splitCsvLine(String line) {
    final parts = <String>[];
    final buf = StringBuffer();
    var inQuotes = false;
    for (var i = 0; i < line.length; i++) {
      final c = line[i];
      if (c == '"') {
        inQuotes = !inQuotes;
      } else if ((c == ',' || c == ';') && !inQuotes) {
        parts.add(buf.toString());
        buf.clear();
      } else {
        buf.write(c);
      }
    }
    parts.add(buf.toString());
    return parts;
  }

  static int _indexOfName(List<String> header) {
    final lower = header.map((e) => e.trim().toLowerCase()).toList();
    final i = lower.indexWhere(
      (h) => h == 'name' || h == 'اسم' || h == 'account' || h == 'account_name',
    );
    return i;
  }

  static int _indexOfNature(List<String> header) {
    final lower = header.map((e) => e.trim().toLowerCase()).toList();
    return lower.indexWhere(
      (h) =>
          h == 'nature' ||
          h == 'طبيعة' ||
          h == 'type' ||
          h == 'debit_credit',
    );
  }
}
