import 'dart:typed_data';

import 'package:excel/excel.dart';

/// Builds `.xlsx` exports with professional branded styling matching Qayd's identity.
///
/// Brand palette:
///   Navy  : #0F2741 (headers, text)
///   Gold  : #C9A227 (accents, header bg)
///   Emerald: #047857 (positive/credit)
///   Slate : #F1F5F9 (alternating rows)
abstract final class QaydExcelWorkbook {
  // ── Brand colours ──────────────────────────────────────────────────────────
  static const String _navy = 'FF0F2741';
  static const String _gold = 'FFC9A227';
  static const String _white = 'FFFFFFFF';
  static const String _slate50 = 'FFF8FAFC';
  static const String _slate100 = 'FFF1F5F9';
  static const String _headerBlue = 'FF8FAADC';
  static const String _black = 'FF000000';
  static const String _errorRed = 'FFD32F2F';

  // ── Shared styles ──────────────────────────────────────────────────────────

  static CellStyle _brandHeaderStyle() => CellStyle(
        bold: true,
        fontSize: 14,
        fontColorHex: ExcelColor.fromHexString(_white),
        backgroundColorHex: ExcelColor.fromHexString(_navy),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
      );

  static CellStyle _tableHeaderStyle() => CellStyle(
        bold: true,
        fontSize: 10,
        backgroundColorHex: ExcelColor.fromHexString(_headerBlue),
        fontColorHex: ExcelColor.fromHexString(_black),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );

  static CellStyle _tableDataStyle({bool alternate = false}) => CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_black),
        backgroundColorHex: ExcelColor.fromHexString(
          alternate ? _slate100 : _white,
        ),
        horizontalAlign: HorizontalAlign.Center,
        verticalAlign: VerticalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Hair),
      );

  static CellStyle _labelStyle() => CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_navy),
        horizontalAlign: HorizontalAlign.Right,
      );

  static CellStyle _valueStyle() => CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_black),
        horizontalAlign: HorizontalAlign.Right,
        bottomBorder: Border(borderStyle: BorderStyle.Dotted),
      );

  static CellStyle _totalsLabelStyle() => CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_navy),
        horizontalAlign: HorizontalAlign.Right,
      );

  static CellStyle _totalsValueStyle() => CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_black),
        horizontalAlign: HorizontalAlign.Left,
        bottomBorder: Border(borderStyle: BorderStyle.Dotted),
      );

  static CellStyle _totalRowLabelStyle() => CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_navy),
        backgroundColorHex: ExcelColor.fromHexString(_slate50),
        horizontalAlign: HorizontalAlign.Right,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );

  static CellStyle _totalRowValueStyle() => CellStyle(
        bold: true,
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_navy),
        backgroundColorHex: ExcelColor.fromHexString(_slate50),
        horizontalAlign: HorizontalAlign.Left,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        topBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );

  static CellStyle _noteStyle() => CellStyle(
        fontSize: 9,
        fontColorHex: ExcelColor.fromHexString(_errorRed),
        bold: true,
        horizontalAlign: HorizontalAlign.Right,
      );

  // ── Simple header write (for vouchers/accounts) ────────────────────────────

  static CellStyle _simpleHeaderStyle() => CellStyle(
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
      cell.cellStyle = _simpleHeaderStyle();
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

  // ══════════════════════════════════════════════════════════════════════════
  // ── VOUCHERS (simple table export) ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // ── ACCOUNTS (simple table export) ─────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════════
  // ── ACCOUNT STATEMENT (professional branded template) ──────────────────
  // ══════════════════════════════════════════════════════════════════════════

  /// Builds a professionally formatted account statement matching the
  /// branded HTML template design with header, info tables, data grid,
  /// totals section, and footer.
  static Uint8List buildAccountStatement({
    required String accountName,
    required List<String> headers,
    required List<List<Object?>> rows,
    // Additional metadata for the full statement template
    String? counterpartyName,
    String? statementDate,
    String? referenceNumber,
    String? openingBalance,
    String? periodFrom,
    String? periodTo,
    String? totalDebit,
    String? totalCredit,
    String? netBalance,
    String? notesText,
  }) {
    var safeName = accountName.replaceAll(RegExp(r'[/\\?*:\[\]]'), '_');
    if (safeName.length > 28) safeName = safeName.substring(0, 28);
    final tab = 'كشف_$safeName';
    final excel = _baseExcel(tab);
    final sheet = excel[tab];

    // Column widths (A=0 through G=6, roughly 7 columns to match template)
    // Columns: التاريخ | المرجع | البيان | العملة | المبلغ | السداد | المبلغ المستحق
    sheet.setColumnWidth(0, 18); // A - التاريخ
    sheet.setColumnWidth(1, 16); // B - المرجع / رقم السند
    sheet.setColumnWidth(2, 14); // C - البيان / النوع
    sheet.setColumnWidth(3, 10); // D - الحالة / العملة
    sheet.setColumnWidth(4, 16); // E - مدين
    sheet.setColumnWidth(5, 16); // F - دائن
    sheet.setColumnWidth(6, 18); // G - الرصيد

    int currentRow = 0;

    // ── ROW 0-1: Brand Header Bar ──────────────────────────────────────────
    // Merge cells for the brand header across all 7 columns
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
    );
    final brandCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    brandCell.value = TextCellValue('قيد — Qayd App');
    brandCell.cellStyle = _brandHeaderStyle();
    currentRow++;

    // Sub-header: "كشف حساب" (Account Statement title)
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
    );
    final titleCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    titleCell.value = TextCellValue('كشف حساب');
    titleCell.cellStyle = CellStyle(
      bold: true,
      fontSize: 12,
      fontColorHex: ExcelColor.fromHexString(_gold),
      backgroundColorHex: ExcelColor.fromHexString(_navy),
      horizontalAlign: HorizontalAlign.Center,
      verticalAlign: VerticalAlign.Center,
    );
    currentRow++;

    // Spacer row
    currentRow++;

    // ── ROW 3-6: Info Section (إلى / من) ────────────────────────────────────
    // Left side: "إلى:" (counterparty) — columns 0-2
    // Right side: "من:" (account owner) — columns 4-6

    void _writeInfoPair(int row, String label, String value, int startCol) {
      final labelC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: startCol, rowIndex: row),
      );
      labelC.value = TextCellValue(label);
      labelC.cellStyle = _labelStyle();

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: startCol + 1, rowIndex: row),
        CellIndex.indexByColumnRow(columnIndex: startCol + 2, rowIndex: row),
      );
      final valueC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: startCol + 1, rowIndex: row),
      );
      valueC.value = TextCellValue(value);
      valueC.cellStyle = _valueStyle();
    }

    _writeInfoPair(currentRow, 'إلى:', counterpartyName ?? accountName, 0);
    _writeInfoPair(currentRow, 'من:', 'بيانات صاحب الحساب', 4);
    currentRow++;

    // Period row
    if (periodFrom != null || periodTo != null) {
      final periodStr = '${periodFrom ?? '…'} — ${periodTo ?? '…'}';
      _writeInfoPair(currentRow, 'الفترة:', periodStr, 0);
    }
    currentRow++;

    // Spacer row
    currentRow++;

    // ── ROW: Date & Meta info ──────────────────────────────────────────────
    _writeInfoPair(
      currentRow,
      'التاريخ:',
      statementDate ?? '',
      0,
    );
    _writeInfoPair(
      currentRow,
      'رقم المرجع:',
      referenceNumber ?? '',
      4,
    );
    currentRow++;

    if (openingBalance != null && openingBalance.isNotEmpty) {
      _writeInfoPair(
        currentRow,
        'الرصيد الافتتاحي:',
        openingBalance,
        4,
      );
    }
    currentRow++;

    // Spacer row
    currentRow++;

    // ── Main Table Headers ─────────────────────────────────────────────────
    for (var i = 0; i < headers.length && i < 7; i++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: currentRow),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = _tableHeaderStyle();
    }
    currentRow++;

    // ── Data Rows ──────────────────────────────────────────────────────────
    final dataStartRow = currentRow;
    for (var r = 0; r < rows.length; r++) {
      final row = rows[r];
      final isAlt = r.isOdd;
      for (var c = 0; c < row.length && c < 7; c++) {
        final cell = sheet.cell(
          CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
        );
        final v = row[c];
        cell.value = TextCellValue(v?.toString() ?? '');
        cell.cellStyle = _tableDataStyle(alternate: isAlt);
      }
      currentRow++;
    }

    // Add minimum empty rows to keep table tall enough (professional look)
    final minTableRows = 7;
    final emptyRowsNeeded = minTableRows - rows.length;
    if (emptyRowsNeeded > 0) {
      for (var r = 0; r < emptyRowsNeeded; r++) {
        final isAlt = (rows.length + r).isOdd;
        for (var c = 0; c < headers.length && c < 7; c++) {
          final cell = sheet.cell(
            CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow),
          );
          cell.value = TextCellValue('');
          cell.cellStyle = _tableDataStyle(alternate: isAlt);
        }
        currentRow++;
      }
    }

    // Bottom border for last data row
    for (var c = 0; c < headers.length && c < 7; c++) {
      final cell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: c, rowIndex: currentRow - 1),
      );
      cell.cellStyle = CellStyle(
        fontSize: 10,
        backgroundColorHex: ExcelColor.fromHexString(
          (currentRow - 1 - dataStartRow).isOdd ? _slate100 : _white,
        ),
        horizontalAlign: HorizontalAlign.Center,
        leftBorder: Border(borderStyle: BorderStyle.Thin),
        rightBorder: Border(borderStyle: BorderStyle.Thin),
        bottomBorder: Border(borderStyle: BorderStyle.Thin),
      );
    }

    // Spacer row
    currentRow++;

    // ── Totals Section ─────────────────────────────────────────────────────
    // Notes on left (columns 0-2), totals on right (columns 4-6)

    if (notesText != null && notesText.isNotEmpty) {
      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 2, rowIndex: currentRow + 1),
      );
      final notesCell = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      );
      notesCell.value = TextCellValue(notesText);
      notesCell.cellStyle = CellStyle(
        fontSize: 10,
        fontColorHex: ExcelColor.fromHexString(_navy),
        horizontalAlign: HorizontalAlign.Right,
        verticalAlign: VerticalAlign.Top,
      );
    }

    // Totals on right side
    if (totalDebit != null && totalDebit.isNotEmpty) {
      final labelC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
      );
      labelC.value = TextCellValue('إجمالي المدين');
      labelC.cellStyle = _totalsLabelStyle();

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      final valC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
      );
      valC.value = TextCellValue(totalDebit);
      valC.cellStyle = _totalsValueStyle();
      currentRow++;
    }

    if (totalCredit != null && totalCredit.isNotEmpty) {
      final labelC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
      );
      labelC.value = TextCellValue('إجمالي الدائن');
      labelC.cellStyle = _totalsLabelStyle();

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      final valC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
      );
      valC.value = TextCellValue(totalCredit);
      valC.cellStyle = _totalsValueStyle();
      currentRow++;
    }

    // Net balance (total row with border)
    if (netBalance != null && netBalance.isNotEmpty) {
      final labelC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 4, rowIndex: currentRow),
      );
      labelC.value = TextCellValue('الرصيد الصافي');
      labelC.cellStyle = _totalRowLabelStyle();

      sheet.merge(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
        CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
      );
      final valC = sheet.cell(
        CellIndex.indexByColumnRow(columnIndex: 5, rowIndex: currentRow),
      );
      valC.value = TextCellValue(netBalance);
      valC.cellStyle = _totalRowValueStyle();
      currentRow++;
    }

    // Spacer
    currentRow++;

    // ── Currency Note ──────────────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
    );
    final noteCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 3, rowIndex: currentRow),
    );
    noteCell.value = TextCellValue(
      '* في حال وجود عملات متعددة، يتم عرض الإجماليات بشكل منفصل لكل عملة.',
    );
    noteCell.cellStyle = _noteStyle();
    currentRow++;

    // Spacer
    currentRow++;

    // ── Footer: Source label ───────────────────────────────────────────────
    sheet.merge(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
      CellIndex.indexByColumnRow(columnIndex: 6, rowIndex: currentRow),
    );
    final footerCell = sheet.cell(
      CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: currentRow),
    );
    footerCell.value = TextCellValue(
      'تم إنشاء هذا الكشف بواسطة تطبيق قيد — Qayd App',
    );
    footerCell.cellStyle = CellStyle(
      fontSize: 8,
      fontColorHex: ExcelColor.fromHexString('FF64748B'),
      horizontalAlign: HorizontalAlign.Center,
    );

    final raw = excel.save(fileName: 'qayd_statement.xlsx');
    return Uint8List.fromList(raw ?? const []);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // ── COMBINED EXPORT ────────────────────────────────────────────────────
  // ══════════════════════════════════════════════════════════════════════════

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
