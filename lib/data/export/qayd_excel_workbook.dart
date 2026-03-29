import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Builds `.xlsx` exports with navy/gold header styling (aligned with PDF branding).
abstract final class QaydExcelWorkbook {
  static const String _gold = 'FFC9A227';
  static const String _navy = 'FF0F2741';

  static CellStyle _headerStyle() => CellStyle(
        bold: true,
        backgroundColorHex: ExcelColor.fromHexString(_gold),
        fontColorHex: ExcelColor.fromHexString(_navy),
        horizontalAlign: HorizontalAlign.Center,
      );

  static void _writeHeader(Sheet sheet, List<String> headers) {
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _headerStyle();
    }
  }

  static void _writeRows(Sheet sheet, List<List<Object?>> rows, int startRow) {
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      for (var c = 0; c < row.length; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(
            columnIndex: c,
            rowIndex: startRow + r,
          ),
        );
        final v = row[c];
        cell.value = TextCellValue(v?.toString() ?? '');
      }
    }
  }

  static Excel _baseExcel(String firstSheetName) {
    final excel = Excel.createExcel();
    final first = excel.sheets.keys.first;
    excel.rename(first, firstSheetName);
    return excel;
  }

  static Uint8List buildVouchers({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final excel = _baseExcel('السندات');
    final sheet = excel['السندات'];
    _writeHeader(sheet, headers);
    _writeRows(sheet, rows, 1);
    final raw = excel.save(fileName: 'qayd_vouchers.xlsx');
    return Uint8List.fromList(raw ?? const []);
  }

  static Uint8List buildAccounts({
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    final excel = _baseExcel('الحسابات');
    final sheet = excel['الحسابات'];
    _writeHeader(sheet, headers);
    _writeRows(sheet, rows, 1);
    final raw = excel.save(fileName: 'qayd_accounts.xlsx');
    return Uint8List.fromList(raw ?? const []);
  }

  /// Row 0: account title; row 1: column headers; data from row 2.
  static Uint8List buildAccountStatement({
    required String accountName,
    required List<String> headers,
    required List<List<Object?>> rows,
  }) {
    var safeName = accountName.replaceAll(RegExp(r'[/\\?*:\[\]]'), '_');
    if (safeName.length > 28) safeName = safeName.substring(0, 28);
    final tab = 'كشف_$safeName';
    final excel = _baseExcel(tab);
    final sheet = excel[tab];
    final title = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
    );
    title.value = TextCellValue(accountName);
    title.cellStyle = _headerStyle();
    for (var i = 0; i < headers.length; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 1),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _headerStyle();
    }
    _writeRows(sheet, rows, 2);
    final raw = excel.save(fileName: 'qayd_statement.xlsx');
    return Uint8List.fromList(raw ?? const []);
  }

  static Uint8List buildCombined({
    required List<String> voucherHeaders,
    required List<List<Object?>> voucherRows,
    required List<String> accountHeaders,
    required List<List<Object?>> accountRows,
  }) {
    final excel = Excel.createExcel();
    final first = excel.sheets.keys.first;
    excel.rename(first, 'السندات');
    final v = excel['السندات'];
    _writeHeader(v, voucherHeaders);
    _writeRows(v, voucherRows, 1);
    final a = excel['الحسابات'];
    _writeHeader(a, accountHeaders);
    _writeRows(a, accountRows, 1);
    final raw = excel.save(fileName: 'qayd_export_all.xlsx');
    return Uint8List.fromList(raw ?? const []);
  }
}
