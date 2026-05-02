import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:qayd/application/accounts/dtos/account_statement_line_dto.dart';
import 'package:qayd/application/accounts/dtos/account_summary_dto.dart';
import 'package:qayd/application/vouchers/dtos/voucher_summary_dto.dart';
import 'package:qayd/data/export/qayd_excel_workbook.dart';
import 'package:qayd/presentation/l10n/app_strings_ar.dart';
import 'package:qayd/core/utils/text_sanitizer.dart';

String _moneyMinor(int minorUnits, {int digits = 2, String? symbol}) {
  num divisor = 1;
  for (var i = 0; i < digits; i++) {
    divisor *= 10;
  }
  final v = minorUnits / divisor;
  final formatted = NumberFormat('#,##0.${'0' * digits}', 'ar').format(v);
  return symbol != null ? '$formatted $symbol' : formatted;
}

String _formatDateIso(String iso) {
  try {
    final d = DateTime.parse(iso);
    return DateFormat.yMMMd('ar').format(d);
  } catch (_) {
    return iso;
  }
}

String _voucherTypeAr(String code) {
  switch (code) {
    case 'receipt':
      return AppStringsAr.voucherTypeReceipt;
    case 'payment':
      return AppStringsAr.voucherTypePayment;
    default:
      return code;
  }
}

String _voucherStateAr(String code) {
  switch (code) {
    case 'draft':
      return AppStringsAr.voucherStateDraft;
    case 'confirmed':
      return AppStringsAr.voucherStateConfirmed;
    case 'settled':
      return AppStringsAr.voucherStateSettled;
    default:
      return code;
  }
}

String _natureAr(String code) {
  switch (code) {
    case 'debit':
      return AppStringsAr.natureDebitShort;
    case 'credit':
      return AppStringsAr.natureCreditShort;
    default:
      return code;
  }
}

String _agreementStatusAr(String code) {
  switch (code) {
    case 'underRequest':
      return AppStringsAr.agreementUnderRequest;
    case 'accepted':
      return AppStringsAr.agreementAccepted;
    case 'rejected':
      return AppStringsAr.agreementRejected;
    case 'unverified':
      return AppStringsAr.agreementUnverified;
    default:
      return code;
  }
}

Uint8List buildVouchersExcelBytes(List<VoucherSummaryDto> vouchers) {
  final headers = [
    'التاريخ',
    'النوع',
    'الحالة',
    'اتفاق التوقيع',
    'المبلغ',
    'الطرف المقابل',
    'الحساب المتأثر',
    'المعرّف',
  ];
  final rows = <List<Object?>>[];
  for (final v in vouchers) {
    rows.add([
      _formatDateIso(v.dateIso),
      _voucherTypeAr(v.typeCode),
      _voucherStateAr(v.stateCode),
      _agreementStatusAr(v.receiverStatusCode),
      _moneyMinor(
        v.amountMinorUnits,
        digits: v.currencyDigits,
        symbol: v.currencySymbol,
      ),
      v.counterpartyName,
      v.affectedName,
      v.id,
    ]);
  }
  return QaydExcelWorkbook.buildVouchers(headers: headers, rows: rows);
}

Uint8List buildAccountsExcelBytes(List<AccountSummaryDto> accounts) {
  final headers = [
    'اسم الحساب',
    'الطبيعة',
    'الرصيد',
    'نشط',
    'جذر',
    'المعرّف',
  ];
  final rows = <List<Object?>>[];
  for (final a in accounts) {
    rows.add([
      a.name,
      _natureAr(a.natureCode),
      a.balancesMinorUnits.entries
          .map((e) => _moneyMinor(e.value, symbol: e.key))
          .join(', '),
      a.isActive ? AppStringsAr.statusActive : AppStringsAr.statusInactive,
      a.isRoot ? AppStringsAr.accountTypeRoot : AppStringsAr.accountTypeChild,
      a.id,
    ]);
  }
  return QaydExcelWorkbook.buildAccounts(headers: headers, rows: rows);
}

Uint8List buildAccountStatementExcelBytes({
  required String accountName,
  required List<AccountStatementLineDto> lines,
  String? issuerName,
}) {
  final headers = [
    'التاريخ',
    'رقم السند',
    'البيان',
    'الحالة',
    'دائن',
    'مدين',
  ];
  final rows = <List<Object?>>[];
  int totalDebit = 0;
  int totalCredit = 0;
  for (final line in lines) {
    totalDebit += line.debitMinorUnits;
    totalCredit += line.creditMinorUnits;
    rows.add([
      _formatDateIso(line.dateIso),
      line.voucherId.length > 10
          ? '${line.voucherId.substring(0, 8)}…'
          : line.voucherId,
      TextSanitizer.sanitizeText(line.description),
      '—',
      line.debitMinorUnits > 0 ? _moneyMinor(line.debitMinorUnits) : '',
      line.creditMinorUnits > 0 ? _moneyMinor(line.creditMinorUnits) : '',
    ]);
  }
  final netBalance = lines.isNotEmpty ? lines.last.balanceMinorUnits : 0;
  return QaydExcelWorkbook.buildAccountStatement(
    accountName: TextSanitizer.sanitizeText(accountName),
    headers: headers,
    rows: rows,
    statementDate: _formatDateIso(DateTime.now().toIso8601String()),
    totalDebit: _moneyMinor(totalDebit),
    totalCredit: _moneyMinor(totalCredit),
    netBalance: _moneyMinor(netBalance),
    notesText: 'شكراً لتعاملكم معنا!\nيرجى مراجعة الأرصدة والتأكد من صحتها.',
    issuerName: issuerName,
  );
}

Uint8List buildCombinedExportExcelBytes({
  required List<VoucherSummaryDto> vouchers,
  required List<AccountSummaryDto> accounts,
}) {
  final vHeaders = [
    'التاريخ',
    'النوع',
    'الحالة',
    'اتفاق التوقيع',
    'المبلغ',
    'الطرف المقابل',
    'الحساب المتأثر',
  ];
  final vRows = <List<Object?>>[];
  for (final v in vouchers) {
    vRows.add([
      _formatDateIso(v.dateIso),
      _voucherTypeAr(v.typeCode),
      _voucherStateAr(v.stateCode),
      _agreementStatusAr(v.receiverStatusCode),
      _moneyMinor(
        v.amountMinorUnits,
        digits: v.currencyDigits,
        symbol: v.currencySymbol,
      ),
      v.counterpartyName,
      v.affectedName,
    ]);
  }
  final aHeaders = [
    'اسم الحساب',
    'الطبيعة',
    'الرصيد',
    'نشط',
  ];
  final aRows = <List<Object?>>[];
  for (final a in accounts) {
    aRows.add([
      a.name,
      _natureAr(a.natureCode),
      a.balancesMinorUnits.entries
          .map((e) => _moneyMinor(e.value, symbol: e.key))
          .join(', '),
      a.isActive ? AppStringsAr.statusActive : AppStringsAr.statusInactive,
    ]);
  }
  return QaydExcelWorkbook.buildCombined(
    voucherHeaders: vHeaders,
    voucherRows: vRows,
    accountHeaders: aHeaders,
    accountRows: aRows,
  );
}

// ── Isolate Wrappers for compute() ──────────────────────────────────────────

Uint8List buildCombinedExportWrapper(Map<String, dynamic> params) {
  return buildCombinedExportExcelBytes(
    vouchers: params['vouchers'] as List<VoucherSummaryDto>,
    accounts: params['accounts'] as List<AccountSummaryDto>,
  );
}

Uint8List buildVouchersExportWrapper(List<VoucherSummaryDto> vouchers) {
  return buildVouchersExcelBytes(vouchers);
}

Uint8List buildAccountStatementWrapper(Map<String, dynamic> params) {
  return buildAccountStatementExcelBytes(
    accountName: params['accountName'] as String,
    lines: params['lines'] as List<AccountStatementLineDto>,
    issuerName: params['issuerName'] as String?,
  );
}
