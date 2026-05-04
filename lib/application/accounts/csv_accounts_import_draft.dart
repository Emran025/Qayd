import 'package:qayd/core/error/failures.dart';
import 'package:qayd/core/result/result.dart';
import 'package:qayd/presentation/l10n/app_strings.dart';


/// Parsed CSV row for future account import (no persistence yet).
class CsvAccountImportDraftRow {
  const CsvAccountImportDraftRow({
    required this.lineNumber,
    required this.name,
    this.natureHint,
    this.phoneNumber,
    this.whatsappNumber,
  });

  final int lineNumber;
  final String name;
  final String? natureHint;
  final String? phoneNumber;
  final String? whatsappNumber;
}

/// Minimal CSV parser: expects a header with `name` / `اسم` and optional `nature` / `طبيعة`.
abstract final class CsvAccountsImportDraft {
  static Result<List<CsvAccountImportDraftRow>> parse(String csvText) {
    final lines = csvText.split(RegExp(r'\r?\n'));
    if (lines.isEmpty) {
      return  FailureResult(
        ValidationFailure(
          messageAr: AppStrings.theFileIsEmpty,
          code: 'csv_empty',
        ),
      );
    }
    final header = _splitCsvLine(lines.first);
    final nameIdx = _indexOfName(header);
    if (nameIdx < 0) {
      return  FailureResult(
        ValidationFailure(
          messageAr: AppStrings.theFirstRowMust,
          code: 'csv_header',
        ),
      );
    }
    final natureIdx = _indexOfNature(header);
    final phoneIdx = _indexOfPhone(header);
    final whatsappIdx = _indexOfWhatsapp(header);

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

      String? phone;
      if (phoneIdx >= 0 && phoneIdx < cells.length) {
        final p = cells[phoneIdx].trim();
        if (p.isNotEmpty) phone = p;
      }

      String? whatsapp;
      if (whatsappIdx >= 0 && whatsappIdx < cells.length) {
        final w = cells[whatsappIdx].trim();
        if (w.isNotEmpty) whatsapp = w;
      }

      out.add(
        CsvAccountImportDraftRow(
          lineNumber: i + 1,
          name: name,
          natureHint: nature,
          phoneNumber: phone,
          whatsappNumber: whatsapp,
        ),
      );
    }
    if (out.isEmpty) {
      return  FailureResult(
        ValidationFailure(
          messageAr: AppStrings.noValidDataRows,
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
      (h) => h == 'name' || h == AppStrings.name || h == 'account' || h == 'account_name',
    );
    return i;
  }

  static int _indexOfNature(List<String> header) {
    final lower = header.map((e) => e.trim().toLowerCase()).toList();
    return lower.indexWhere(
      (h) =>
          h == 'nature' || h == AppStrings.nature || h == 'type' || h == 'debit_credit',
    );
  }

  static int _indexOfPhone(List<String> header) {
    final lower = header.map((e) => e.trim().toLowerCase()).toList();
    return lower.indexWhere(
      (h) => h == 'phone' || h == AppStrings.phone || h == 'mobile' || h == AppStrings.cellPhone,
    );
  }

  static int _indexOfWhatsapp(List<String> header) {
    final lower = header.map((e) => e.trim().toLowerCase()).toList();
    return lower.indexWhere(
      (h) => h == 'whatsapp' || h == AppStrings.watts || h == AppStrings.whatsapp,
    );
  }
}
